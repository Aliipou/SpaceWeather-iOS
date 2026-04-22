import asyncio
import logging
import random
from datetime import date, timedelta

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_client: httpx.AsyncClient | None = None


def get_client() -> httpx.AsyncClient:
    global _client
    if _client is None or _client.is_closed:
        _client = httpx.AsyncClient(timeout=httpx.Timeout(15.0), follow_redirects=True)
    return _client


async def close_client() -> None:
    global _client
    if _client and not _client.is_closed:
        await _client.aclose()


async def _fetch_with_retry(url: str, params: dict, max_attempts: int = 3) -> dict | list:
    base_delay = 1.0
    last_exc: Exception | None = None
    for attempt in range(max_attempts):
        try:
            resp = await get_client().get(url, params=params)
            resp.raise_for_status()
            return resp.json()
        except (httpx.HTTPStatusError, httpx.RequestError) as exc:
            last_exc = exc
            if isinstance(exc, httpx.HTTPStatusError) and exc.response.status_code < 500:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 0.5)
            logger.warning("NASA API attempt %d failed: %s — retrying in %.1fs", attempt + 1, exc, delay)
            await asyncio.sleep(delay)
    raise RuntimeError(f"NASA API unavailable after {max_attempts} attempts") from last_exc


async def fetch_apod_random(count: int = 20) -> list[dict]:
    data = await _fetch_with_retry(
        f"{settings.nasa_base_url}/planetary/apod",
        {"api_key": settings.nasa_api_key, "count": count},
    )
    return data if isinstance(data, list) else [data]


async def fetch_apod_date_range(start_date: str, end_date: str) -> list[dict]:
    data = await _fetch_with_retry(
        f"{settings.nasa_base_url}/planetary/apod",
        {"api_key": settings.nasa_api_key, "start_date": start_date, "end_date": end_date},
    )
    return data if isinstance(data, list) else [data]


async def fetch_apod_date(apod_date: str) -> dict:
    data = await _fetch_with_retry(
        f"{settings.nasa_base_url}/planetary/apod",
        {"api_key": settings.nasa_api_key, "date": apod_date},
    )
    return data if isinstance(data, dict) else data[0]


async def fetch_mars_photos(rover: str, sol: int, camera: str | None, page: int) -> dict:
    params: dict = {
        "api_key": settings.nasa_api_key,
        "sol": sol,
        "page": page,
    }
    if camera:
        params["camera"] = camera
    return await _fetch_with_retry(
        f"{settings.nasa_base_url}/mars-photos/api/v1/rovers/{rover}/photos",
        params,
    )


async def fetch_mars_latest(rover: str) -> dict:
    return await _fetch_with_retry(
        f"{settings.nasa_base_url}/mars-photos/api/v1/rovers/{rover}/latest_photos",
        {"api_key": settings.nasa_api_key},
    )


async def prefetch_todays_apod() -> None:
    today = date.today().isoformat()
    try:
        await fetch_apod_date(today)
        logger.info("Pre-fetched today's APOD (%s)", today)
    except Exception as exc:
        logger.error("APOD pre-fetch failed: %s", exc)
