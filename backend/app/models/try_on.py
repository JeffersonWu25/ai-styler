import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, created_at_column


class TryOn(Base):
    __tablename__ = "try_ons"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), index=True
    )
    outfit_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("outfits.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    image_key: Mapped[str] = mapped_column(String(512))
    created_at: Mapped[datetime] = created_at_column()
