import uuid

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    outfit_name: Mapped[str] = mapped_column(Text)
    shirt_id = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("clothes.id", ondelete="SET NULL"),
        nullable=True,
    )
    bottom_id = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("clothes.id", ondelete="SET NULL"),
        nullable=True,
    )
    outerwear_id = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("clothes.id", ondelete="SET NULL"),
        nullable=True,
    )
    shoe_id = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("clothes.id", ondelete="SET NULL"),
        nullable=True,
    )
    reference_image_url = mapped_column(String(512), nullable=True)
