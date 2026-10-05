import uuid
from datetime import datetime

from app.models import ClothingCategory, SavedLook
from app.schemas.base import CamelModel
from app.services import storage


class SavedLookCreateRequest(CamelModel):
    try_on_id: uuid.UUID


class SavedLookItemResponse(CamelModel):
    category: ClothingCategory
    name: str
    brand: str
    listing_url: str
    image_url: str


class SavedLookOutfitResponse(CamelModel):
    name: str
    items: list[SavedLookItemResponse]


class SavedLookResponse(CamelModel):
    id: uuid.UUID
    try_on_id: uuid.UUID | None
    image_url: str
    created_at: datetime
    outfit: SavedLookOutfitResponse

    @classmethod
    def from_model(cls, saved_look: SavedLook) -> "SavedLookResponse":
        snapshot = saved_look.outfit_snapshot
        return cls(
            id=saved_look.id,
            try_on_id=saved_look.try_on_id,
            image_url=storage.presigned_url(saved_look.image_key),
            created_at=saved_look.created_at,
            outfit=SavedLookOutfitResponse(
                name=snapshot["name"],
                items=[
                    SavedLookItemResponse(
                        category=item["category"],
                        name=item["name"],
                        brand=item["brand"],
                        listing_url=item["listing_url"],
                        image_url=storage.presigned_url(item["image_key"]),
                    )
                    for item in snapshot["items"]
                ],
            ),
        )
