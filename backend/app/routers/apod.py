from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query

from app.auth.dependencies import get_current_user_optional
from app.config import get_settings
from app.database.models import User
from app.models.apod import AstronomyPicture, ApodPage
from app.services import cache_service as cs
from app.services.nasa_service import fetch_apod_date, fetch_apod_date_range, fetch_apod_random

router = APIRouter(prefix="/apod", tags=["apod"])
settings = get_settings()


@router.get("/random", response_model=list[AstronomyPicture])
async def get_random(
    count: int = Query(default=20, ge=1, le=100),
    _user: User | None = Depends(get_current_user_optional),
) -> list[AstronomyPicture]:
    key = f"apod:random:{count}"
    cached = cs.cache.get(key)
    if cached:
        return cached

    raw = await fetch_apod_random(count)
    pictures = [AstronomyPicture.from_nasa(item) for item in raw]
    cs.cache.set(key, pictures, ttl=settings.apod_cache_ttl_seconds)
    return pictures


@router.get("/today", response_model=AstronomyPicture)
async def get_today(
    _user: User | None = Depends(get_current_user_optional),
) -> AstronomyPicture:
    today = date.today().isoformat()
    key = f"apod:date:{today}"
    cached = cs.cache.get(key)
    if cached:
        return cached

    raw = await fetch_apod_date(today)
    picture = AstronomyPicture.from_nasa(raw)
    cs.cache.set(key, picture, ttl=settings.apod_cache_ttl_seconds)
    return picture


@router.get("/date/{apod_date}", response_model=AstronomyPicture)
async def get_by_date(
    apod_date: str,
    _user: User | None = Depends(get_current_user_optional),
) -> AstronomyPicture:
    key = f"apod:date:{apod_date}"
    cached = cs.cache.get(key)
    if cached:
        return cached

    raw = await fetch_apod_date(apod_date)
    picture = AstronomyPicture.from_nasa(raw)
    cs.cache.set(key, picture, ttl=settings.apod_range_cache_ttl_seconds)
    return picture


@router.get("/feed", response_model=ApodPage)
async def get_feed(
    cursor: str | None = Query(default=None, description="ISO date — fetch days ending here"),
    page_size: int = Query(default=20, ge=1, le=50),
    _user: User | None = Depends(get_current_user_optional),
) -> ApodPage:
    """Cursor-based paginated APOD feed, newest-first. Equivalent to Android's ApodPagingSource."""
    end = date.fromisoformat(cursor) if cursor else date.today()
    start = end - timedelta(days=page_size - 1)

    key = f"apod:feed:{start}:{end}"
    from_cache = False
    cached = cs.cache.get(key)

    if cached:
        pictures = cached
        from_cache = True
    else:
        raw = await fetch_apod_date_range(start.isoformat(), end.isoformat())
        pictures = sorted(
            [AstronomyPicture.from_nasa(item) for item in raw],
            key=lambda p: p.date,
            reverse=True,
        )
        cs.cache.set(key, pictures, ttl=settings.apod_range_cache_ttl_seconds)

    next_cursor = (start - timedelta(days=1)).isoformat() if len(pictures) >= page_size else None

    return ApodPage(
        items=pictures,
        next_cursor=next_cursor,
        has_more=next_cursor is not None,
        from_cache=from_cache,
        cache_hit_rate_pct=cs.cache.stats.hit_rate,
    )
