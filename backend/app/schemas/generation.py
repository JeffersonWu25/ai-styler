from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class GenerationResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    outfit_name: str = Field(alias="outfitName")
    is_saved: bool = Field(alias="isSaved")
    created_at: datetime = Field(alias="createdAt")


class TryOnResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    generation_id: str = Field(alias="generationId")
    image_base64: str = Field(alias="imageBase64")
    outfit_name: str = Field(alias="outfitName")
