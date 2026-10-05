import uuid
from datetime import datetime

from app.models import Outfit
from app.schemas.base import CamelModel
from app.schemas.clothes import ClothingItemResponse
from app.services import storage


class OutfitSummaryResponse(CamelModel):
    id: uuid.UUID
    name: str
    reference_image_url: str | None
    created_at: datetime

    @classmethod
    def from_model(cls, outfit: Outfit) -> "OutfitSummaryResponse":
        return cls(
            id=outfit.id,
            name=outfit.name,
            reference_image_url=(
                storage.presigned_url(outfit.reference_image_key)
                if outfit.reference_image_key
                else None
            ),
            created_at=outfit.created_at,
        )


class OutfitResponse(OutfitSummaryResponse):
    items: list[ClothingItemResponse]

    @classmethod
    def from_model(cls, outfit: Outfit) -> "OutfitResponse":
        return cls(
            **OutfitSummaryResponse.from_model(outfit).model_dump(),
            items=[ClothingItemResponse.from_model(item) for item in outfit.items],
        )
