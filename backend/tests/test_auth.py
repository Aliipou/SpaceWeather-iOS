import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_creates_user_and_returns_tokens(client: AsyncClient):
    resp = await client.post("/v1/auth/register", json={
        "email": "test@example.com", "password": "securepass123"
    })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate_email_returns_409(client: AsyncClient):
    payload = {"email": "dup@example.com", "password": "securepass123"}
    await client.post("/v1/auth/register", json=payload)
    resp = await client.post("/v1/auth/register", json=payload)
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login_valid_credentials(client: AsyncClient):
    await client.post("/v1/auth/register", json={"email": "login@example.com", "password": "securepass123"})
    resp = await client.post("/v1/auth/login", json={"email": "login@example.com", "password": "securepass123"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_password_returns_401(client: AsyncClient):
    await client.post("/v1/auth/register", json={"email": "wrong@example.com", "password": "securepass123"})
    resp = await client.post("/v1/auth/login", json={"email": "wrong@example.com", "password": "wrongpass"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_auth(client: AsyncClient):
    resp = await client.get("/v1/auth/me")
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_me_returns_user_info(client: AsyncClient):
    reg = await client.post("/v1/auth/register", json={"email": "me@example.com", "password": "securepass123"})
    token = reg.json()["access_token"]
    resp = await client.get("/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["email"] == "me@example.com"


@pytest.mark.asyncio
async def test_refresh_token_rotation(client: AsyncClient):
    reg = await client.post("/v1/auth/register", json={"email": "refresh@example.com", "password": "securepass123"})
    refresh_token = reg.json()["refresh_token"]
    resp = await client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_refresh_token_replay_rejected(client: AsyncClient):
    reg = await client.post("/v1/auth/register", json={"email": "replay@example.com", "password": "securepass123"})
    refresh_token = reg.json()["refresh_token"]
    await client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    resp = await client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_logout_revokes_tokens(client: AsyncClient):
    reg = await client.post("/v1/auth/register", json={"email": "logout@example.com", "password": "securepass123"})
    tokens = reg.json()
    await client.post("/v1/auth/logout", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    resp = await client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_weak_password_rejected(client: AsyncClient):
    resp = await client.post("/v1/auth/register", json={"email": "weak@example.com", "password": "123"})
    assert resp.status_code == 422
