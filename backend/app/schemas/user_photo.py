from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserPhotoResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    slot: str
    updated_at: datetime = Field(alias="updatedAt")


class UserPhotosListResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    photos: list[UserPhotoResponse]
