import re

def test_cors_headers(fixture_origin, fixture_url):
    """Test Cross Origin Requests"""
    # Act
    response = fixture_origin.options(fixture_url)
    # Assert
    cors_headers = {
        'access-control-allow-origin',
        'access-control-allow-methods',
        'access-control-allow-headers',
    }
    assert cors_headers.issubset({ header.lower() for header in response.headers.keys() })


def test_cors_allow_origin(fixture_origin, fixture_url):
    """Test Cross Origin Requests"""
    # Act
    response = fixture_origin.options(fixture_url)
    # Assert
    assert response.headers['access-control-allow-origin'] == '*'


def test_create_todo_item(fixture_session, fixture_create_item, fixture_item):
    """Test Create Todo Item """
    # Assert
    item_url = fixture_create_item.headers['location']
    match = re.match(r'^https?://.*/todos/([\d]+)$', item_url)
    assert fixture_create_item.status_code == 201
    assert match
    # Check created item matches input data
    item_id = match.group(1)
    result = fixture_session.get(item_url).json()
    assert result == { 
        'id': item_id,
        'url': item_url,
        **fixture_create_item,
    }


def test_put_todo_item(fixture_session, fixture_create_item):
    # Arrange
    item = fixture_create_item.json()
    item_url = fixture_create_item.headers['location']
    assert item['completed'] == False
    item['completed'] = True
    # Act
    response = fixture_session.put(item_url, json=item)
    # Assert
    assert response.status_code == 200
    assert response.json() == item


def test_patch_todo_item(session, fixture_create_item):
    # Arrange
    item = fixture_create_item.json()
    item_url = fixture_create_item.headers['location']
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