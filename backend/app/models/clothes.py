import enum
import uuid
from datetime import datetime

from sqlalchemy import Enum, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, created_at_column


class ClothingCategory(str, enum.Enum):
    SHIRT = "shirt"
    BOTTOM = "bottom"
    OUTERWEAR = "outerwear"
    SHOE = "shoe"


class ClothingItem(Base):
    __tablename__ = "clothes"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    category: Mapped[ClothingCategory] = mapped_column(
        Enum(
            ClothingCategory,
            name="clothing_category",
            native_enum=True,
            values_callable=lambda items: [item.value for item in items],
        )
    )
    name: Mapped[str] = mapped_column(Text)
    brand: Mapped[str] = mapped_column(Text)
    listing_url: Mapped[str] = mapped_column(Text)
    image_key: Mapped[str] = mapped_column(String(512))
    created_at: Mapped[datetime] = created_at_column()
