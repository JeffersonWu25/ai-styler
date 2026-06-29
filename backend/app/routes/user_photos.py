import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.user_photo import UserPhotoResponse, UserPhotosListResponse
from app.services.object_storage import ObjectStorageError, download_user_photo
from app.services.user_photos import (
    UserPhotoError,
    delete_user_photo,
    get_user_photo,
    list_user_photos,
    upsert_user_photo,
    validate_slot,
)

router = APIRouter(prefix="/user-photos", tags=["user-photos"])

MAX_IMAGE_BYTES = 15 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "application/octet-stream"}


@router.get("", response_model=UserPhotosListResponse)
async def list_photos(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserPhotosListResponse:
    photos = await list_user_photos(db, current_user.id)
    return UserPhotosListResponse(photos=[_to_response(photo) for photo in photos])


@router.put("/{slot}", response_model=UserPhotoResponse)
async def upload_photo(
    slot: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    image: UploadFile = File(...),
) -> UserPhotoResponse:
    try:
        validate_slot(slot)
    except UserPhotoError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    image_bytes = await _read_image(image, slot)

    try:
        content_type = image.content_type or "image/jpeg"
        photo = await upsert_user_photo(
            db,
            current_user.id,
            slot,
            image_bytes,
            content_type=content_type,
        )
    except UserPhotoError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return _to_response(photo)


@router.get("/{slot}/image")
async def get_photo_image(
    slot: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> Response:
    try:
        validate_slot(slot)
    except UserPhotoError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    photo = await get_user_photo(db, current_user.id, slot)
    if photo is None:
        raise HTTPException(status_code=404, detail="Photo not found.")

    try:
        image_bytes = download_user_photo(photo.object_key)
    except ObjectStorageError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return Response(content=image_bytes, media_type=photo.content_type)


@router.delete("/{slot}", status_code=204)
async def remove_photo(
    slot: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    try:
        validate_slot(slot)
    except UserPhotoError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        await delete_user_photo(db, current_user.id, slot)
    except UserPhotoError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


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


def _to_response(photo) -> UserPhotoResponse:
    return UserPhotoResponse(slot=photo.slot, updated_at=photo.updated_at)
