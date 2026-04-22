from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.database.database import get_db
from app.database.models import Favorite, User
from app.models.apod import AstronomyPicture

router = APIRouter(prefix="/favorites", tags=["favorites"])


class FavoriteIn(BaseModel):
    date: str
    title: str
    url: str
    hd_url: str | None = None
    explanation: str
    media_type: str
    copyright: str | None = None


class FavoriteOut(BaseModel):
    id: int
    apod_date: str
    title: str
    url: str
    hd_url: str | None
    explanation: str
    media_type: str
    copyright: str | None

    model_config = {"from_attributes": True}


@router.get("", response_model=list[FavoriteOut])
async def list_favorites(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FavoriteOut]:
    result = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id).order_by(Favorite.saved_at.desc())
    )
    return [FavoriteOut.model_validate(f) for f in result.scalars()]


@router.post("", response_model=FavoriteOut, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    body: FavoriteIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FavoriteOut:
    existing = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == body.date)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already favorited")

    fav = Favorite(
        user_id=current_user.id,
        apod_date=body.date,
        title=body.title,
        url=body.url,
        hd_url=body.hd_url,
        explanation=body.explanation,
        media_type=body.media_type,
        copyright=body.copyright,
    )
    db.add(fav)
    await db.commit()
    await db.refresh(fav)
    return FavoriteOut.model_validate(fav)


@router.delete("/{apod_date}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    apod_date: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == apod_date)
    )
    fav = result.scalar_one_or_none()
    if not fav:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found")
    await db.delete(fav)
    await db.commit()


@router.get("/check/{apod_date}")
async def is_favorite(
    apod_date: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    result = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == apod_date)
    )
    return {"is_favorite": result.scalar_one_or_none() is not None}
