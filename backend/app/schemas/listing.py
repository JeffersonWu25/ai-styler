from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ListingResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    title: str
    brand: str
    url: str
    price: Decimal | None = None
    currency: str
    category: str | None = None
    created_at: datetime = Field(alias="createdAt")


class ListingCreateFields(BaseModel):
    """Validated form fields for listing create (image handled separately)."""

    title: str
    brand: str
    url: HttpUrl
    price: Decimal | None = None
    currency: str = "USD"
    category: str | None = None
