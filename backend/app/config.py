import ssl
from pathlib import Path
from urllib.parse import urlparse

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = BACKEND_ROOT / "assets"


def normalize_database_url(url: str) -> str:
    if url.startswith("postgres://"):
        return "postgresql+asyncpg://" + url.removeprefix("postgres://")
    if url.startswith("postgresql://") and "+asyncpg" not in url:
        return "postgresql+asyncpg://" + url.removeprefix("postgresql://")
    return url


def database_connect_args(url: str, *, verify_ssl: bool) -> dict:
    parsed = urlparse(url.replace("+asyncpg", ""))
    host = parsed.hostname or ""
    if host in {"127.0.0.1", "localhost"}:
        return {}

    ssl_context = ssl.create_default_context()
    if not verify_ssl:
        # Railway public Postgres uses a cert chain that fails strict verification
        # from local machines. Encryption is still enabled; only CA verify is skipped.
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
    return {"ssl": ssl_context}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openai_api_key: str = ""
    openai_image_model: str = "gpt-image-2"
    openai_image_quality: str = "medium"
    openai_image_size: str = "1536x1024"
    default_outfit_id: str = "old-money"

    database_url: str = ""
    database_ssl_verify: bool = False
    jwt_secret: str = "dev-only-change-me"

    s3_endpoint: str = ""
    s3_access_key_id: str = ""
    s3_secret_access_key: str = ""
    s3_bucket_name: str = ""
    s3_region: str = "auto"

    @field_validator("database_url")
    @classmethod
    def require_database_url(cls, value: str) -> str:
        normalized = normalize_database_url(value.strip())
        if not normalized:
            raise ValueError(
                "DATABASE_URL is required in backend/.env. "
                "Copy the public Postgres URL from your Railway project."
            )
        host = urlparse(normalized.replace("+asyncpg", "")).hostname or ""
        if host.endswith(".railway.internal"):
            raise ValueError(
                "DATABASE_URL uses a Railway private hostname (*.railway.internal), "
                "which only works inside Railway. For local uvicorn, use the public "
                "Postgres URL from Railway → Postgres service → Connect → Public URL "
                "(host ends in .railway.app)."
            )
        return normalized


settings = Settings()
