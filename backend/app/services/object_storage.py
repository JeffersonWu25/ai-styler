import uuid

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from app.config import settings


class ObjectStorageError(Exception):
    pass


def _require_s3_config() -> None:
    missing = [
        name
        for name, value in {
            "S3_ENDPOINT": settings.s3_endpoint,
            "S3_ACCESS_KEY_ID": settings.s3_access_key_id,
            "S3_SECRET_ACCESS_KEY": settings.s3_secret_access_key,
            "S3_BUCKET_NAME": settings.s3_bucket_name,
        }.items()
        if not value
    ]
    if missing:
        raise ObjectStorageError(
            "Object storage is not configured. Set "
            + ", ".join(missing)
            + " in backend/.env (Railway Storage Bucket credentials)."
        )


def _s3_client():
    _require_s3_config()
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
        region_name=settings.s3_region or "auto",
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "virtual"},
        ),
    )


def generation_object_key(user_id: uuid.UUID, generation_id: uuid.UUID) -> str:
    return f"generations/{user_id}/{generation_id}.png"


def upload_generation(
    user_id: uuid.UUID, generation_id: uuid.UUID, png_bytes: bytes
) -> str:
    object_key = generation_object_key(user_id, generation_id)
    try:
        _s3_client().put_object(
            Bucket=settings.s3_bucket_name,
            Key=object_key,
            Body=png_bytes,
            ContentType="image/png",
        )
    except ClientError as exc:
        error = exc.response.get("Error", {})
        code = error.get("Code", "Unknown")
        message = error.get("Message", "Upload failed.")
        if code == "InvalidAccessKeyId":
            raise ObjectStorageError(
                "S3 credentials were rejected. In Railway → your bucket → Credentials, "
                "copy fresh credentials into backend/.env (or reset them) and restart uvicorn."
            ) from exc
        raise ObjectStorageError(f"Failed to upload generation image: {message}") from exc
    return object_key


def download_generation(object_key: str) -> bytes:
    try:
        response = _s3_client().get_object(
            Bucket=settings.s3_bucket_name,
            Key=object_key,
        )
        return response["Body"].read()
    except ClientError as exc:
        raise ObjectStorageError("Failed to download generation image.") from exc
