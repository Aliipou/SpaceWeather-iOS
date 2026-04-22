from pydantic import BaseModel, HttpUrl


class AstronomyPicture(BaseModel):
    date: str
    title: str
    explanation: str
    url: str
    hd_url: str | None = None
    media_type: str
    service_version: str = "v1"
    copyright: str | None = None

    @classmethod
    def from_nasa(cls, data: dict) -> "AstronomyPicture":
        return cls(
            date=data["date"],
            title=data["title"],
            explanation=data["explanation"],
            url=data["url"],
            hd_url=data.get("hdurl"),
            media_type=data.get("media_type", "image"),
            service_version=data.get("service_version", "v1"),
            copyright=data.get("copyright", "").strip() or None,
        )

    def is_image(self) -> bool:
        return self.media_type == "image"


class ApodPage(BaseModel):
    items: list[AstronomyPicture]
    next_cursor: str | None = None   # ISO date of the oldest item's day minus 1
    has_more: bool
    from_cache: bool = False
    cache_hit_rate_pct: float = 0.0
