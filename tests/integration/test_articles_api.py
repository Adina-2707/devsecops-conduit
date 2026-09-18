import httpx


def test_registered_user_can_publish_and_read_article(api_url, registered_user):
    title = f"Hello from {registered_user['username']}"
    payload = {"article": {"title": title, "description": "A test article", "body": "Hello from a test!", "tagList": ["tests"]}}
    headers = {"Authorization": f"Token {registered_user['token']}"}

    created = httpx.post(f"{api_url}/api/articles", json=payload, headers=headers, timeout=15)
    assert created.status_code == 200, created.text
    slug = created.json()["article"]["slug"]

    fetched = httpx.get(f"{api_url}/api/articles/{slug}", timeout=15)
    assert fetched.status_code == 200, fetched.text
    assert fetched.json()["article"]["title"] == title
    assert fetched.json()["article"]["author"]["username"] == registered_user["username"]


def test_anonymous_user_cannot_publish(api_url):
    payload = {"article": {"title": "No token", "description": "Denied", "body": "No", "tagList": []}}
    response = httpx.post(f"{api_url}/api/articles", json=payload, timeout=15)
    assert response.status_code == 403, response.text
