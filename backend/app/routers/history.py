from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.database.database import get_db
from app.database.models import SearchHistory, User

router = APIRouter(prefix="/history", tags=["history"])


class HistoryIn(BaseModel):
    query: str
    result_type: str   # "apod" | "mars"
    result_date: str | None = None


class HistoryOut(BaseModel):
    id: int
    query: str
    result_type: str
    result_date: str | None
    searched_at: str

    model_config = {"from_attributes": True}


@router.get("", response_model=list[HistoryOut])
async def list_history(
    limit: int = Query(default=50, le=200),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[HistoryOut]:
    result = await db.execute(
        select(SearchHistory)
        .where(SearchHistory.user_id == current_user.id)
        .order_by(SearchHistory.searched_at.desc())
        .limit(limit)
    )
    return [
        HistoryOut(
            id=h.id,
            query=h.query,
            result_type=h.result_type,
            result_date=h.result_date,
            searched_at=h.searched_at.isoformat(),
        )
        for h in result.scalars()
    ]


@router.post("", response_model=HistoryOut, status_code=201)
async def add_history(
    body: HistoryIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> HistoryOut:
    entry = SearchHistory(
        user_id=current_user.id,
        query=body.query,
        result_type=body.result_type,
        result_date=body.result_date,
    )
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return HistoryOut(
        id=entry.id,
        query=entry.query,
        result_type=entry.result_type,
        result_date=entry.result_date,
        searched_at=entry.searched_at.isoformat(),
    )


@router.delete("", status_code=204)
async def clear_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await db.execute(delete(SearchHistory).where(SearchHistory.user_id == current_user.id))
    await db.commit()
