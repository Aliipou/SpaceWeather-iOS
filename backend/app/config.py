from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # NASA
    nasa_api_key: str = "DEMO_KEY"
    nasa_base_url: str = "https://api.nasa.gov"

    # Auth
    secret_key: str = "change-me-in-production-at-least-32-chars"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # Database
    database_url: str = "sqlite+aiosqlite:///./spaceexplorer.db"

    # Cache
    apod_cache_ttl_seconds: int = 3600        # 1h for today's APOD
    apod_range_cache_ttl_seconds: int = 86400  # 24h for historical
    mars_cache_ttl_seconds: int = 3600

    # Rate limiting
    rate_limit_per_minute: int = 60

    # CORS
    allowed_origins: list[str] = ["*"]

    # Background scheduler
    apod_prefetch_hour: int = 6   # pre-fetch at 06:00 UTC daily


@lru_cache
def get_settings() -> Settings:
    return Settings()
