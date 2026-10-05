from fastapi import APIRouter, UploadFile

from app.deps.auth import CurrentUser, DbSession
from app.models import PhotoSlot
from app.schemas.user import PhotoResponse, UserResponse
from app.services import storage
from app.services.uploads import read_image

router = APIRouter(prefix="/user", tags=["user"])


@router.get("", response_model=UserResponse)
async def get_user(user: CurrentUser) -> UserResponse:
    return UserResponse.from_model(user)


@router.put("/photos/{slot}", response_model=PhotoResponse)
async def put_photo(
    slot: PhotoSlot, image: UploadFile, user: CurrentUser, db: DbSession
) -> PhotoResponse:
    upload = await read_image(image, slot.value)
    previous_key = user.photo_key(slot)
    key = storage.user_photo_key(user.id, slot.value, upload.content_type)
    storage.put_object(key, upload.data, upload.content_type)

    user.set_photo_key(slot, key)
    await db.commit()
    if previous_key and previous_key != key:
        storage.delete_object(previous_key)

    return PhotoResponse.from_user(user, slot)


@router.delete("/photos/{slot}", status_code=204)
async def delete_photo(slot: PhotoSlot, user: CurrentUser, db: DbSession) -> None:
    key = user.photo_key(slot)
    if key is None:
        return
    user.set_photo_key(slot, None)
    await db.commit()
    storage.delete_object(key)
