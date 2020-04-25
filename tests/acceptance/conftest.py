import os

import requests
import pytest

def create_session():
    """Create a requests session object"""
    session = requests.session()
    session.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Connection': 'close'
    }
    return session


@pytest.fixture(scope='session')
def fixture_url():
    """Test Server URL Fixture"""
    yield os.environ.get('TEST_URL', 'http://localhost:8000/todos')


@pytest.fixture
def fixture_session():
    """HTTP client session fixture"""
    fixture_session = create_session()
    yield fixture_session


@pytest.fixture
def fixture_origin(fixture_session):
    """HTTP client session fixture with origin header"""
    fixture_session.headers = {
        **fixture_session.headers,
        'Origin': 'http://example.com'
    }
    yield fixture_session


@pytest.fixture
def fixture_item():
    """Todo item"""
    yield { 
        'title': 'Walk the dog',
        'completed': False,
        'order': 1
    }


@pytest.fixture
def fixture_create_item(fixture_url, fixture_item):
    """Creates todo item"""
    session = create_session()
    response = session.post(fixture_url, json=fixture_item)
    item_url = response.headers['location']
    yield response
    session.delete(item_url)