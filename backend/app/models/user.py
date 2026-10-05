import enum
import uuid

from sqlalchemy import String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

SEED_USER_ID = uuid.UUID("d21bf82d-306d-4bcc-b4ac-905d2736443f")


class PhotoSlot(str, enum.Enum):
    FRONT = "front"
    SIDE = "side"
    BACK = "back"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True)
    username: Mapped[str] = mapped_column(String(255), unique=True)
    front_photo_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    side_photo_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    back_photo_key: Mapped[str | None] = mapped_column(String(512), nullable=True)

    def photo_key(self, slot: PhotoSlot) -> str | None:
        return getattr(self, f"{slot.value}_photo_key")

    def set_photo_key(self, slot: PhotoSlot, key: str | None) -> None:
        setattr(self, f"{slot.value}_photo_key", key)
