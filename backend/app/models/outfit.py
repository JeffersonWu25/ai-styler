import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, created_at_column
from app.models.clothes import ClothingItem


def _item_fk() -> Mapped[uuid.UUID | None]:
    return mapped_column(
        Uuid(as_uuid=True), ForeignKey("clothes.id", ondelete="SET NULL"), nullable=True
    )


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(Text)
    shirt_id: Mapped[uuid.UUID | None] = _item_fk()
    bottom_id: Mapped[uuid.UUID | None] = _item_fk()
    outerwear_id: Mapped[uuid.UUID | None] = _item_fk()
    shoe_id: Mapped[uuid.UUID | None] = _item_fk()
    reference_image_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    created_at: Mapped[datetime] = created_at_column()

    shirt: Mapped[ClothingItem | None] = relationship(foreign_keys=[shirt_id], lazy="selectin")
    bottom: Mapped[ClothingItem | None] = relationship(foreign_keys=[bottom_id], lazy="selectin")
    outerwear: Mapped[ClothingItem | None] = relationship(
        foreign_keys=[outerwear_id], lazy="selectin"
    )
    shoe: Mapped[ClothingItem | None] = relationship(foreign_keys=[shoe_id], lazy="selectin")

    @property
    def items(self) -> list[ClothingItem]:
        return [
            item
            for item in (self.shirt, self.bottom, self.outerwear, self.shoe)
            if item is not None
        ]
