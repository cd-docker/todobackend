import os

import requests
import pytest

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
        'Accept': 'application/json',
        'Connection': 'close'
    }
    yield session


@pytest.fixture
def origin(session):
    """HTTP client session fixture with origin header"""
    session.headers = {
        **session.headers,
        'Origin': 'http://example.com'
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
    yield session.post(url, json=item)