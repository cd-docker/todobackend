import re
import os

import pytest
import requests


@pytest.fixture(scope='session')
def url():
    """Test Server URL Fixture"""
    yield os.environ.get('TEST_URL', 'http://localhost:8000/todos')


@pytest.fixture
def session():
    """HTTP client session fixture"""
    session = requests.session()
    session.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    yield session


@pytest.fixture
def item():
    """Todo item"""
    yield { 
        'title': 'Walk the dog',
        'completed': False,
        'order': 1
    }


@pytest.fixture
def create_item(session, url, item):
    """Creates todo item"""
    yield requests.post(url, headers=session.headers, json=item)


def test_cors_headers(session, url):
    """Test Cross Origin Requests"""
    # Arrange
    session.headers['Origin'] = 'http://example.com'
    # Act
    response = session.options(url)
    # Assert
    cors_headers = {
        'access-control-allow-origin',
        'access-control-allow-methods',
        'access-control-allow-headers',
    }
    assert cors_headers.issubset({ header.lower() for header in response.headers.keys() })


def test_cors_allow_origin(session, url):
    """Test Cross Origin Requests"""
    # Arrange
    session.headers['Origin'] = 'http://example.com'
    # Act
    response = session.options(url)
    # Assert
    assert response.headers['access-control-allow-origin'] == '*'


def test_create_todo_item(session, create_item, item):
    """Test Create Todo Item """
    # Assert
    assert create_item.status_code == 201
    assert re.match(r'^https?://.*/todos/[\d]+$', create_item.headers['location'])
    # Check created item matches input data
    result = session.get(create_item.headers['location']).json()
    assert result == { **item, 'url': create_item.headers['location'] }


def test_put_todo_item(session, create_item):
    # Arrange
    item = create_item.json()
    item_url = create_item.headers['location']
    assert item['completed'] == False
    item['completed'] = True
    # Act
    response = session.put(item_url, json=item)
    # Assert
    assert response.status_code == 200
    assert response.json() == item


def test_patch_todo_item(session, create_item):
    # Arrange
    item = create_item.json()
    item_url = create_item.headers['location']
    assert item['completed'] == False
    patch = {'completed': True}
    # Act
    response = session.patch(item_url, json=patch)
    # Assert
    assert response.status_code == 200
    assert response.json() == { **item, **patch }


def test_delete_todo_item(session, url, create_item):
    # Arrange
    item = create_item.json()
    item_url = create_item.headers['location']
    # Act
    response = session.delete(item_url)
    # Assert
    assert response.status_code == 204
