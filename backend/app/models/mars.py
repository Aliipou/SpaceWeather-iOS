from pydantic import BaseModel


class MarsCamera(BaseModel):
    id: int
    name: str
    rover_id: int
    full_name: str


class MarsRover(BaseModel):
    id: int
    name: str
    landing_date: str
    launch_date: str
    status: str


class MarsPhoto(BaseModel):
    id: int
    sol: int
    camera: MarsCamera
    img_src: str
    earth_date: str
    rover: MarsRover

    @classmethod
    def from_nasa(cls, data: dict) -> "MarsPhoto":
        return cls(**data)


class MarsPage(BaseModel):
    photos: list[MarsPhoto]
    page: int
    per_page: int = 25
    has_more: bool
    from_cache: bool = False
    cache_hit_rate_pct: float = 0.0
