import pytest
from httpx import AsyncClient


async def _register_and_token(client: AsyncClient, email: str) -> str:
    resp = await client.post("/v1/auth/register", json={"email": email, "password": "securepass123"})
    return resp.json()["access_token"]


@pytest.mark.asyncio
async def test_add_and_list_history(client: AsyncClient):
    token = await _register_and_token(client, "hist@example.com")
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/v1/history", json={"query": "galaxy", "result_type": "apod"}, headers=headers)
    resp = await client.get("/v1/history", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 1
    assert resp.json()[0]["query"] == "galaxy"


@pytest.mark.asyncio
async def test_clear_history(client: AsyncClient):
    token = await _register_and_token(client, "clrhist@example.com")
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/v1/history", json={"query": "mars", "result_type": "mars"}, headers=headers)
    await client.delete("/v1/history", headers=headers)
    resp = await client.get("/v1/history", headers=headers)
    assert resp.json() == []


@pytest.mark.asyncio
async def test_history_requires_auth(client: AsyncClient):
    resp = await client.get("/v1/history")
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_history_isolated_per_user(client: AsyncClient):
    token_a = await _register_and_token(client, "ha@example.com")
    token_b = await _register_and_token(client, "hb@example.com")
    await client.post("/v1/history", json={"query": "nebula", "result_type": "apod"},
                      headers={"Authorization": f"Bearer {token_a}"})
    resp = await client.get("/v1/history", headers={"Authorization": f"Bearer {token_b}"})
    assert resp.json() == []
