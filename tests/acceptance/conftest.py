import os

import requests
import pytest

@pytest.fixture(scope='session')
def fixture_url():
    """Test Server URL Fixture"""
    yield os.environ.get('TEST_URL', 'http://localhost:8000/todos')


@pytest.fixture
def fixture_session():
    """HTTP client session fixture"""
    fixture_session = requests.session()
    fixture_session.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Connection': 'close'
    }
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
def fixture_create_item(fixture_session, fixture_url, fixture_item):
    """Creates todo item"""
    yield fixture_session.post(fixture_url, json=fixture_item)