import pytest
from httpx import AsyncClient


async def _register_and_token(client: AsyncClient, email: str) -> str:
    resp = await client.post("/v1/auth/register", json={"email": email, "password": "securepass123"})
    return resp.json()["access_token"]


@pytest.mark.asyncio
async def test_get_profile_returns_user_data(client: AsyncClient):
    token = await _register_and_token(client, "profile@example.com")
    resp = await client.get("/v1/profile", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "profile@example.com"
    assert data["favorites_count"] == 0


@pytest.mark.asyncio
async def test_update_display_name(client: AsyncClient):
    token = await _register_and_token(client, "update@example.com")
    resp = await client.patch(
        "/v1/profile",
        json={"display_name": "Astro"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["display_name"] == "Astro"


@pytest.mark.asyncio
async def test_profile_requires_auth(client: AsyncClient):
    resp = await client.get("/v1/profile")
    assert resp.status_code == 403
