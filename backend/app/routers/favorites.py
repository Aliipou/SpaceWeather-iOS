from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.database.database import get_db
from app.database.models import Favorite, User

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
    saved_at: str

    model_config = {"from_attributes": True}


class SyncRequest(BaseModel):
    favorites: list[FavoriteIn]


class SyncResponse(BaseModel):
    added: int
    skipped: int
    total: int


def _to_out(f: Favorite) -> FavoriteOut:
    return FavoriteOut(
        id=f.id,
        apod_date=f.apod_date,
        title=f.title,
        url=f.url,
        hd_url=f.hd_url,
        explanation=f.explanation,
        media_type=f.media_type,
        copyright=f.copyright,
        saved_at=f.saved_at.isoformat(),
    )


@router.get("", response_model=list[FavoriteOut])
async def list_favorites(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FavoriteOut]:
    result = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id).order_by(Favorite.saved_at.desc())
    )
    return [_to_out(f) for f in result.scalars()]


@router.post("", response_model=FavoriteOut, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    body: FavoriteIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FavoriteOut:
    existing = (await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == body.date)
    )).scalar_one_or_none()
    if existing:
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
    return _to_out(fav)


@router.post("/sync", response_model=SyncResponse)
async def sync_favorites(
    body: SyncRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncResponse:
    """Bulk upsert — idempotent device → server sync."""
    existing_dates = {
        row for (row,) in (await db.execute(
            select(Favorite.apod_date).where(Favorite.user_id == current_user.id)
        )).all()
    }
    added = 0
    skipped = 0
    for item in body.favorites:
        if item.date in existing_dates:
            skipped += 1
            continue
        db.add(Favorite(
            user_id=current_user.id,
            apod_date=item.date,
            title=item.title,
            url=item.url,
            hd_url=item.hd_url,
            explanation=item.explanation,
            media_type=item.media_type,
            copyright=item.copyright,
        ))
        existing_dates.add(item.date)
        added += 1

    if added:
        await db.commit()

    total = len(existing_dates)
    return SyncResponse(added=added, skipped=skipped, total=total)


@router.delete("/{apod_date}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    apod_date: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    fav = (await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == apod_date)
    )).scalar_one_or_none()
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
    result = (await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.apod_date == apod_date)
    )).scalar_one_or_none()
    return {"is_favorite": result is not None}
