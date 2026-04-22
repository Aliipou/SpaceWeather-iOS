from datetime import date, timedelta
from fastapi import APIRouter, Depends, Query
from app.auth.dependencies import get_current_user_optional
from app.database.models import User
from app.services import cache_service as cs
from app.services.nasa_service import _fetch_with_retry
from app.config import get_settings

router = APIRouter(prefix="/solar", tags=["solar"])
settings = get_settings()

DONKI_BASE = "https://api.nasa.gov/DONKI"


async def _donki(endpoint: str, start: str, end: str) -> list[dict]:
    return await _fetch_with_retry(
        f"{DONKI_BASE}/{endpoint}",
        {"api_key": settings.nasa_api_key, "startDate": start, "endDate": end},
    )


@router.get("/flares")
async def solar_flares(
    days: int = Query(default=7, ge=1, le=30),
    _user: User | None = Depends(get_current_user_optional),
) -> dict:
    """Solar flares from NASA DONKI — class A/B/C/M/X with peak time and region."""
    end = date.today()
    start = end - timedelta(days=days)
    key = f"solar:flares:{start}:{end}"
    cached = cs.cache.get(key)
    if cached:
        return {"data": cached, "from_cache": True}
    raw = await _donki("FLR", start.isoformat(), end.isoformat())
    result = [
        {
            "flare_id": f.get("flrID"),
            "begin_time": f.get("beginTime"),
            "peak_time": f.get("peakTime"),
            "end_time": f.get("endTime"),
            "class": f.get("classType"),
            "source_location": f.get("sourceLocation"),
            "region": f.get("activeRegionNum"),
            "linked_events": len(f.get("linkedEvents") or []),
        }
        for f in (raw if isinstance(raw, list) else [])
    ]
    cs.cache.set(key, result, ttl=1800)
    return {"data": result, "from_cache": False}


@router.get("/cme")
async def coronal_mass_ejections(
    days: int = Query(default=7, ge=1, le=30),
    _user: User | None = Depends(get_current_user_optional),
) -> dict:
    """Coronal mass ejections — speed, type, and Earth-directed flag."""
    end = date.today()
    start = end - timedelta(days=days)
    key = f"solar:cme:{start}:{end}"
    cached = cs.cache.get(key)
    if cached:
        return {"data": cached, "from_cache": True}
    raw = await _donki("CME", start.isoformat(), end.isoformat())
    result = []
    for cme in (raw if isinstance(raw, list) else []):
        analysis = (cme.get("cmeAnalyses") or [{}])[0]
        result.append({
            "cme_id": cme.get("activityID"),
            "start_time": cme.get("startTime"),
            "source_location": cme.get("sourceLocation"),
            "type": analysis.get("type"),
            "speed_km_s": analysis.get("speed"),
            "half_angle": analysis.get("halfAngle"),
            "is_earth_directed": analysis.get("isMostAccurate", False),
            "note": cme.get("note", "")[:200],
        })
    cs.cache.set(key, result, ttl=1800)
    return {"data": result, "from_cache": False}


@router.get("/storms")
async def geomagnetic_storms(
    days: int = Query(default=30, ge=1, le=90),
    _user: User | None = Depends(get_current_user_optional),
) -> dict:
    """Geomagnetic storms with Kp index — G1 through G5 scale."""
    end = date.today()
    start = end - timedelta(days=days)
    key = f"solar:storms:{start}:{end}"
    cached = cs.cache.get(key)
    if cached:
        return {"data": cached, "from_cache": True}
    raw = await _donki("GST", start.isoformat(), end.isoformat())
    result = [
        {
            "storm_id": s.get("gstID"),
            "start_time": s.get("startTime"),
            "kp_index": max((kp.get("kpIndex", 0) for kp in (s.get("allKpIndex") or [])), default=0),
            "g_scale": _kp_to_g(max((kp.get("kpIndex", 0) for kp in (s.get("allKpIndex") or [])), default=0)),
            "linked_events": len(s.get("linkedEvents") or []),
        }
        for s in (raw if isinstance(raw, list) else [])
    ]
    cs.cache.set(key, result, ttl=1800)
    return {"data": result, "from_cache": False}


@router.get("/dashboard")
async def solar_dashboard(
    _user: User | None = Depends(get_current_user_optional),
) -> dict:
    """Combined 7-day solar activity summary."""
    import asyncio
    flares_task = solar_flares(7, None)
    cme_task = coronal_mass_ejections(7, None)
    storms_task = geomagnetic_storms(30, None)
    flares, cmes, storms = await asyncio.gather(flares_task, cme_task, storms_task)
    return {
        "summary": {
            "flare_count_7d": len(flares["data"]),
            "cme_count_7d": len(cmes["data"]),
            "storm_count_30d": len(storms["data"]),
            "max_flare_class": _max_flare_class(flares["data"]),
            "earth_directed_cmes": sum(1 for c in cmes["data"] if c["is_earth_directed"]),
            "max_kp": max((s["kp_index"] for s in storms["data"]), default=0),
        },
        "recent_flares": flares["data"][:3],
        "recent_cmes": cmes["data"][:3],
        "recent_storms": storms["data"][:3],
    }


def _kp_to_g(kp: float) -> str:
    if kp >= 9: return "G5"
    if kp >= 8: return "G4"
    if kp >= 7: return "G3"
    if kp >= 6: return "G2"
    if kp >= 5: return "G1"
    return "None"


def _max_flare_class(flares: list) -> str:
    order = {"X": 5, "M": 4, "C": 3, "B": 2, "A": 1}
    best = "A"
    for f in flares:
        cls = (f.get("class") or "A")[0].upper()
        if order.get(cls, 0) > order.get(best, 0):
            best = cls
    return best
