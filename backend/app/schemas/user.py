import uuid

from app.models import PhotoSlot, User
from app.schemas.base import CamelModel
from app.services import storage


class PhotoResponse(CamelModel):
    slot: PhotoSlot
    image_url: str

    @classmethod
    def from_user(cls, user: User, slot: PhotoSlot) -> "PhotoResponse | None":
        key = user.photo_key(slot)
        if key is None:
            return None
        return cls(slot=slot, image_url=storage.presigned_url(key))


class UserPhotosResponse(CamelModel):
    front: PhotoResponse | None
    side: PhotoResponse | None
    back: PhotoResponse | None


class UserResponse(CamelModel):
    id: uuid.UUID
    username: str
    email: str
    photos: UserPhotosResponse

    @classmethod
    def from_model(cls, user: User) -> "UserResponse":
        return cls(
            id=user.id,
            username=user.username,
            email=user.email,
            photos=UserPhotosResponse(
                front=PhotoResponse.from_user(user, PhotoSlot.FRONT),
                side=PhotoResponse.from_user(user, PhotoSlot.SIDE),
                back=PhotoResponse.from_user(user, PhotoSlot.BACK),
            ),
        )
