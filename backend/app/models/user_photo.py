import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

VALID_PHOTO_SLOTS = frozenset({"front", "side", "back"})


class UserPhoto(Base):
    __tablename__ = "user_photos"
    __table_args__ = (UniqueConstraint("user_id", "slot", name="uq_user_photos_user_slot"),)

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), index=True
    )
    slot: Mapped[str] = mapped_column(String(16))
    object_key: Mapped[str] = mapped_column(String(512))
    content_type: Mapped[str] = mapped_column(String(64), default="image/jpeg")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
