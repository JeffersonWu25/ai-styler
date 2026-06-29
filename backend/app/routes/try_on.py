import base64
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.catalog.outfits import get_outfit
from app.config import settings
from app.deps.auth import get_current_user
from app.db.session import get_db
from app.models.generation import Generation
from app.models.user import User
from app.schemas.generation import TryOnResponse
from app.services.object_storage import ObjectStorageError, upload_generation
from app.services.openai_image import OpenAIImageError, generate_try_on

router = APIRouter(prefix="/try-on", tags=["try-on"])

MAX_IMAGE_BYTES = 15 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "application/octet-stream"}


@router.post("", response_model=TryOnResponse)
async def try_on(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    front: UploadFile = File(...),
    side: UploadFile = File(...),
    back: UploadFile = File(...),
) -> TryOnResponse:
    front_bytes = await _read_image(front, "front")
    side_bytes = await _read_image(side, "side")
    back_bytes = await _read_image(back, "back")

    try:
        outfit = get_outfit(settings.default_outfit_id)
        garment_paths = outfit.garment_paths()
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except KeyError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    user_images = [
        (front.filename or "front.jpg", front_bytes),
        (side.filename or "side.jpg", side_bytes),
        (back.filename or "back.jpg", back_bytes),
    ]

    try:
        result_bytes = await generate_try_on(
            user_images=user_images,
            garment_paths=garment_paths,
            prompt=outfit.prompt,
        )
    except OpenAIImageError as exc:
        status_code = exc.status_code or 502
        if status_code == 401:
            status_code = 500
        raise HTTPException(status_code=status_code, detail=str(exc)) from exc

    generation_id = uuid.uuid4()
    try:
        object_key = upload_generation(current_user.id, generation_id, result_bytes)
    except ObjectStorageError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    generation = Generation(
        id=generation_id,
        user_id=current_user.id,
        outfit_name=outfit.name,
        object_key=object_key,
    )
    db.add(generation)
    await db.commit()

    return TryOnResponse(
        generation_id=str(generation_id),
        image_base64=base64.b64encode(result_bytes).decode("ascii"),
        outfit_name=outfit.name,
    )


async def _read_image(upload: UploadFile, field_name: str) -> bytes:
    if upload.content_type and upload.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"{field_name} must be a JPEG, PNG, or WebP image.",
        )

    data = await upload.read()
    if not data:
        raise HTTPException(status_code=400, detail=f"{field_name} image is empty.")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"{field_name} image is too large (max 15 MB).",
        )
    return data
