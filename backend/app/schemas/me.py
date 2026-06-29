from pydantic import BaseModel, ConfigDict, Field

from app.schemas.generation import GenerationResponse
from app.schemas.user_photo import UserPhotoResponse


class MeAssetsResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    user_photos: list[UserPhotoResponse] = Field(alias="userPhotos")
    generations: list[GenerationResponse]
