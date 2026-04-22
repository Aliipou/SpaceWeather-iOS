import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_returns_ok(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
    assert "uptime_seconds" in resp.json()


@pytest.mark.asyncio
async def test_metrics_returns_cache_stats(client: AsyncClient):
    resp = await client.get("/metrics")
    assert resp.status_code == 200
    data = resp.json()
    assert "cache" in data
    assert "hit_rate_pct" in data["cache"]
    assert "live_entries" in data["cache"]
    assert "uptime_seconds" in data
