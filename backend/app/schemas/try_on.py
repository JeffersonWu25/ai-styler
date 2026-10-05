import uuid
from datetime import datetime

from app.models import TryOn
from app.schemas.base import CamelModel
from app.services import storage


class TryOnCreateRequest(CamelModel):
    outfit_id: uuid.UUID


class TryOnResponse(CamelModel):
    id: uuid.UUID
    outfit_id: uuid.UUID | None
    outfit_name: str
    image_url: str
    created_at: datetime

    @classmethod
    def from_model(cls, try_on: TryOn, outfit_name: str) -> "TryOnResponse":
        return cls(
            id=try_on.id,
            outfit_id=try_on.outfit_id,
            outfit_name=outfit_name,
            image_url=storage.presigned_url(try_on.image_key),
            created_at=try_on.created_at,
        )
