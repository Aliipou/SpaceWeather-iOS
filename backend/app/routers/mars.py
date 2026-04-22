from fastapi import APIRouter, Depends, Query

from app.auth.dependencies import get_current_user_optional
from app.config import get_settings
from app.database.models import User
from app.models.mars import MarsPage, MarsPhoto
from app.services import cache_service as cs
from app.services.nasa_service import fetch_mars_latest, fetch_mars_photos

router = APIRouter(prefix="/mars", tags=["mars"])
settings = get_settings()

VALID_ROVERS = {"curiosity", "opportunity", "spirit", "perseverance"}
VALID_CAMERAS = {"fhaz", "rhaz", "mast", "chemcam", "mahli", "mardi", "navcam", "pancam", "minites"}


@router.get("/{rover}/photos", response_model=MarsPage)
async def get_photos(
    rover: str,
    sol: int = Query(default=1000, ge=0),
    camera: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    _user: User | None = Depends(get_current_user_optional),
) -> MarsPage:
    rover = rover.lower()
    if rover not in VALID_ROVERS:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=f"Unknown rover. Valid: {', '.join(VALID_ROVERS)}")

    cam_key = camera or "all"
    key = f"mars:{rover}:sol{sol}:cam{cam_key}:page{page}"
    from_cache = False
    cached = cs.cache.get(key)

    if cached:
        photos, total = cached
        from_cache = True
    else:
        raw = await fetch_mars_photos(rover, sol, camera, page)
        photos = [MarsPhoto.model_validate(p) for p in raw.get("photos", [])]
        total = len(photos)
        cs.cache.set(key, (photos, total), ttl=settings.mars_cache_ttl_seconds)

    return MarsPage(
        photos=photos,
        page=page,
        has_more=len(photos) == 25,
        from_cache=from_cache,
        cache_hit_rate_pct=cs.cache.stats.hit_rate,
    )


@router.get("/{rover}/latest", response_model=MarsPage)
async def get_latest(
    rover: str,
    _user: User | None = Depends(get_current_user_optional),
) -> MarsPage:
    rover = rover.lower()
    key = f"mars:{rover}:latest"
    from_cache = False
    cached = cs.cache.get(key)

    if cached:
        photos = cached
        from_cache = True
    else:
        raw = await fetch_mars_latest(rover)
        photos = [MarsPhoto.model_validate(p) for p in raw.get("latest_photos", [])]
        cs.cache.set(key, photos, ttl=settings.mars_cache_ttl_seconds)

    return MarsPage(
        photos=photos,
        page=1,
        has_more=False,
        from_cache=from_cache,
        cache_hit_rate_pct=cs.cache.stats.hit_rate,
    )
