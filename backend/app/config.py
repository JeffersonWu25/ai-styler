from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = BACKEND_ROOT / "assets"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openai_api_key: str = ""
    openai_image_model: str = "gpt-image-2"
    openai_image_quality: str = "medium"
    openai_image_size: str = "1024x1536"
    default_outfit_id: str = "old-money"


settings = Settings()
