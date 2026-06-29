from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps.auth import get_current_user
from app.db.session import get_db
from app.models.generation import Generation
from app.models.user import User
from app.schemas.generation import GenerationResponse
from app.schemas.me import MeAssetsResponse
from app.schemas.user_photo import UserPhotoResponse
from app.services.user_photos import list_user_photos

router = APIRouter(prefix="/me", tags=["me"])


@router.get("/assets", response_model=MeAssetsResponse)
async def get_assets(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MeAssetsResponse:
    photos = await list_user_photos(db, current_user.id)

    result = await db.execute(
        select(Generation)
        .where(Generation.user_id == current_user.id)
        .order_by(Generation.created_at.desc())
    )
    generations = result.scalars().all()

    return MeAssetsResponse(
        user_photos=[
            UserPhotoResponse(slot=photo.slot, updated_at=photo.updated_at)
            for photo in photos
        ],
        generations=[
            GenerationResponse(
                id=str(generation.id),
                outfit_name=generation.outfit_name,
                is_saved=generation.is_saved,
                created_at=generation.created_at,
            )
            for generation in generations
        ],
    )
