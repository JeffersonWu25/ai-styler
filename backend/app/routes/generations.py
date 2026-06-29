import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps.auth import get_current_user
from app.db.session import get_db
from app.models.generation import Generation
from app.models.user import User
from app.schemas.generation import GenerationResponse
from app.services.object_storage import ObjectStorageError, download_generation

router = APIRouter(prefix="/generations", tags=["generations"])


@router.get("", response_model=list[GenerationResponse])
async def list_generations(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    saved: Annotated[bool | None, Query()] = None,
) -> list[GenerationResponse]:
    query = select(Generation).where(Generation.user_id == current_user.id)
    if saved is True:
        query = query.where(Generation.is_saved.is_(True))
    query = query.order_by(Generation.created_at.desc())

    result = await db.execute(query)
    generations = result.scalars().all()
    return [_to_response(generation) for generation in generations]


@router.patch("/{generation_id}/save", response_model=GenerationResponse)
async def save_generation(
    generation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> GenerationResponse:
    generation = await _get_owned_generation(db, generation_id, current_user.id)
    generation.is_saved = True
    await db.commit()
    await db.refresh(generation)
    return _to_response(generation)


@router.get("/{generation_id}/image")
async def get_generation_image(
    generation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> Response:
    generation = await _get_owned_generation(db, generation_id, current_user.id)

    try:
        image_bytes = download_generation(generation.object_key)
    except ObjectStorageError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return Response(content=image_bytes, media_type="image/png")


async def _get_owned_generation(
    db: AsyncSession, generation_id: uuid.UUID, user_id: uuid.UUID
) -> Generation:
    result = await db.execute(
        select(Generation).where(
            Generation.id == generation_id,
            Generation.user_id == user_id,
        )
    )
    generation = result.scalar_one_or_none()
    if generation is None:
        raise HTTPException(status_code=404, detail="Generation not found.")
    return generation


def _to_response(generation: Generation) -> GenerationResponse:
    return GenerationResponse(
        id=str(generation.id),
        outfit_name=generation.outfit_name,
        is_saved=generation.is_saved,
        created_at=generation.created_at,
    )
