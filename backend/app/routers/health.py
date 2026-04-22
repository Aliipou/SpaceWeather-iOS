import time
from fastapi import APIRouter
from app.services.cache_service import cache

router = APIRouter(tags=["health"])
_start_time = time.time()


@router.get("/health")
async def health() -> dict:
    return {"status": "ok", "uptime_seconds": round(time.time() - _start_time, 1)}


@router.get("/metrics")
async def metrics() -> dict:
    """PerformanceTracker equivalent — cache stats + uptime."""
    return {
        "uptime_seconds": round(time.time() - _start_time, 1),
        "cache": {
            **cache.stats.to_dict(),
            "live_entries": cache.size(),
        },
    }
