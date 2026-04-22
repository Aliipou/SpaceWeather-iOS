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

    # Database — defaults to SQLite for local dev, set DATABASE_URL for Postgres in prod
    database_url: str = "sqlite+aiosqlite:///./spaceexplorer.db"

    # Cache
    apod_cache_ttl_seconds: int = 3600
    apod_range_cache_ttl_seconds: int = 86400
    mars_cache_ttl_seconds: int = 3600

    # Rate limiting
    rate_limit_per_minute: int = 60

    # CORS
    allowed_origins: list[str] = ["*"]

    # Background scheduler
    apod_prefetch_hour: int = 6

    # Monitoring
    sentry_dsn: str = ""
    environment: str = "development"

    @property
    def is_postgres(self) -> bool:
        return self.database_url.startswith("postgresql")

    @property
    def async_database_url(self) -> str:
        url = self.database_url
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+asyncpg://", 1)
        elif url.startswith("postgresql://") and "+asyncpg" not in url:
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return url


@lru_cache
def get_settings() -> Settings:
    return Settings()
