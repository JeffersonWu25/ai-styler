import uuid
from datetime import datetime

from app.models import ClothingCategory, ClothingItem
from app.schemas.base import CamelModel
from app.services import storage


class ClothingItemResponse(CamelModel):
    id: uuid.UUID
    category: ClothingCategory
    name: str
    brand: str
    listing_url: str
    image_url: str
    created_at: datetime

    @classmethod
    def from_model(cls, item: ClothingItem) -> "ClothingItemResponse":
        return cls(
            id=item.id,
            category=item.category,
            name=item.name,
            brand=item.brand,
            listing_url=item.listing_url,
            image_url=storage.presigned_url(item.image_key),
            created_at=item.created_at,
        )
