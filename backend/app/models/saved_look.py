import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, ForeignKey, String, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, created_at_column


class SavedLook(Base):
    """A saved try-on result with a frozen copy of the outfit it was generated from.

    `outfit_snapshot` shape:
    {"name": str, "items": [{"category", "name", "brand", "listing_url", "image_key"}]}
    Item image keys point at copies under saved-looks/, so deleting catalog
    clothes never breaks a saved look.
    """

    __tablename__ = "saved_looks"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), index=True
    )
    try_on_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("try_ons.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    image_key: Mapped[str] = mapped_column(String(512))
    outfit_snapshot: Mapped[dict[str, Any]] = mapped_column(
        JSON().with_variant(JSONB(), "postgresql")
    )
    created_at: Mapped[datetime] = created_at_column()
