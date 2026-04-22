import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.auth.router import router as auth_router
from app.config import get_settings
from app.database.database import init_db
from app.middleware.metrics import RequestMetricsMiddleware
from app.routers.apod import router as apod_router
from app.routers.favorites import router as favorites_router
from app.routers.health import router as health_router
from app.routers.mars import router as mars_router
from app.services.nasa_service import close_client, prefetch_todays_apod

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
settings = get_settings()
scheduler = AsyncIOScheduler()
limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    scheduler.add_job(prefetch_todays_apod, "cron", hour=settings.apod_prefetch_hour, minute=0)
    scheduler.start()
    yield
    scheduler.shutdown(wait=False)
    await close_client()


app = FastAPI(
    title="Space Explorer API",
    version="1.0.0",
    description="NASA APOD + Mars Rover backend with auth, pagination, caching, and metrics",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(RequestMetricsMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router, prefix="/v1")
app.include_router(apod_router, prefix="/v1")
app.include_router(mars_router, prefix="/v1")
app.include_router(favorites_router, prefix="/v1")
