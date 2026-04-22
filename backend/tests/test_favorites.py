import pytest
from httpx import AsyncClient

APOD_PAYLOAD = {
    "date": "2024-01-15",
    "title": "Spiral Galaxy",
    "url": "https://apod.nasa.gov/apod/image/galaxy.jpg",
    "explanation": "A beautiful galaxy.",
    "media_type": "image",
}


async def _auth_headers(client: AsyncClient, email: str = "fav@example.com") -> dict:
    resp = await client.post("/v1/auth/register", json={"email": email, "password": "securepass123"})
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


@pytest.mark.asyncio
async def test_list_favorites_empty(client: AsyncClient):
    headers = await _auth_headers(client, "list@example.com")
    resp = await client.get("/v1/favorites", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_add_favorite(client: AsyncClient):
    headers = await _auth_headers(client, "add@example.com")
    resp = await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers)
    assert resp.status_code == 201
    assert resp.json()["apod_date"] == "2024-01-15"


@pytest.mark.asyncio
async def test_add_duplicate_favorite_returns_409(client: AsyncClient):
    headers = await _auth_headers(client, "dup2@example.com")
    await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers)
    resp = await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers)
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_remove_favorite(client: AsyncClient):
    headers = await _auth_headers(client, "remove@example.com")
    await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers)
    resp = await client.delete(f"/v1/favorites/{APOD_PAYLOAD['date']}", headers=headers)
    assert resp.status_code == 204


@pytest.mark.asyncio
async def test_check_favorite(client: AsyncClient):
    headers = await _auth_headers(client, "check@example.com")
    resp = await client.get(f"/v1/favorites/check/{APOD_PAYLOAD['date']}", headers=headers)
    assert resp.json()["is_favorite"] is False
    await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers)
    resp = await client.get(f"/v1/favorites/check/{APOD_PAYLOAD['date']}", headers=headers)
    assert resp.json()["is_favorite"] is True


@pytest.mark.asyncio
async def test_favorites_requires_auth(client: AsyncClient):
    resp = await client.get("/v1/favorites")
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_favorites_isolated_per_user(client: AsyncClient):
    headers_a = await _auth_headers(client, "user_a@example.com")
    headers_b = await _auth_headers(client, "user_b@example.com")
    await client.post("/v1/favorites", json=APOD_PAYLOAD, headers=headers_a)
    resp = await client.get("/v1/favorites", headers=headers_b)
    assert resp.json() == []
