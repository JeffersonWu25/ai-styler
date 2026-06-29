import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_photo import VALID_PHOTO_SLOTS, UserPhoto
from app.services.object_storage import (
    ObjectStorageError,
    delete_user_photo_object,
    download_user_photo,
    upload_user_photo,
)


class UserPhotoError(Exception):
    pass


def validate_slot(slot: str) -> str:
    normalized = slot.lower().strip()
    if normalized not in VALID_PHOTO_SLOTS:
        raise UserPhotoError(f"Invalid photo slot: {slot}")
    return normalized


async def list_user_photos(db: AsyncSession, user_id: uuid.UUID) -> list[UserPhoto]:
    result = await db.execute(
        select(UserPhoto)
        .where(UserPhoto.user_id == user_id)
        .order_by(UserPhoto.slot)
    )
    return list(result.scalars().all())


async def get_user_photo(
    db: AsyncSession, user_id: uuid.UUID, slot: str
) -> UserPhoto | None:
    slot = validate_slot(slot)
    result = await db.execute(
        select(UserPhoto).where(
            UserPhoto.user_id == user_id,
            UserPhoto.slot == slot,
        )
    )
    return result.scalar_one_or_none()


async def upsert_user_photo(
    db: AsyncSession,
    user_id: uuid.UUID,
    slot: str,
    image_bytes: bytes,
    content_type: str = "image/jpeg",
) -> UserPhoto:
    slot = validate_slot(slot)

    try:
        object_key = upload_user_photo(user_id, slot, image_bytes, content_type)
    except ObjectStorageError as exc:
        raise UserPhotoError(str(exc)) from exc

    existing = await get_user_photo(db, user_id, slot)
    now = datetime.now(timezone.utc)

    if existing is None:
        photo = UserPhoto(
            user_id=user_id,
            slot=slot,
            object_key=object_key,
            content_type=content_type,
            updated_at=now,
        )
        db.add(photo)
    else:
        existing.object_key = object_key
        existing.content_type = content_type
        existing.updated_at = now
        photo = existing

    await db.commit()
    await db.refresh(photo)
    return photo


async def load_user_photo_bytes(
    db: AsyncSession, user_id: uuid.UUID, slot: str
) -> bytes | None:
    photo = await get_user_photo(db, user_id, slot)
    if photo is None:
        return None

    try:
        return download_user_photo(photo.object_key)
    except ObjectStorageError as exc:
        raise UserPhotoError(str(exc)) from exc


async def delete_user_photo(db: AsyncSession, user_id: uuid.UUID, slot: str) -> None:
    photo = await get_user_photo(db, user_id, slot)
    if photo is None:
        return

    try:
        delete_user_photo_object(photo.object_key)
    except ObjectStorageError as exc:
        raise UserPhotoError(str(exc)) from exc

    await db.delete(photo)
    await db.commit()
