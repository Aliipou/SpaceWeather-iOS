from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import UserOut
from app.database.database import get_db
from app.database.models import User

router = APIRouter(prefix="/profile", tags=["profile"])


class ProfileUpdate(BaseModel):
    display_name: str | None = None
    avatar_url: str | None = None
    bio: str | None = None


class ProfileOut(BaseModel):
    id: int
    email: str
    display_name: str | None
    avatar_url: str | None
    bio: str | None
    created_at: str
    favorites_count: int = 0

    model_config = {"from_attributes": True}


@router.get("", response_model=ProfileOut)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileOut:
    return ProfileOut(
        id=current_user.id,
        email=current_user.email,
        display_name=current_user.display_name,
        avatar_url=current_user.avatar_url,
        bio=current_user.bio,
        created_at=current_user.created_at.isoformat(),
        favorites_count=len(current_user.favorites),
    )


@router.patch("", response_model=ProfileOut)
async def update_profile(
    body: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileOut:
    if body.display_name is not None:
        current_user.display_name = body.display_name
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url
    if body.bio is not None:
        current_user.bio = body.bio
    await db.commit()
    await db.refresh(current_user)
    return ProfileOut(
        id=current_user.id,
        email=current_user.email,
        display_name=current_user.display_name,
        avatar_url=current_user.avatar_url,
        bio=current_user.bio,
        created_at=current_user.created_at.isoformat(),
        favorites_count=len(current_user.favorites),
    )
