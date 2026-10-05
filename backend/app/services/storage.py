import uuid
from functools import lru_cache

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from app.config import settings
from app.errors import NotConfiguredError, UpstreamError

EXTENSIONS = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


class StorageError(UpstreamError):
    pass


def extension_for(content_type: str) -> str:
    return EXTENSIONS.get(content_type, "jpg")


def content_type_for(key: str) -> str:
    for content_type, extension in EXTENSIONS.items():
        if key.endswith(f".{extension}"):
            return content_type
    return "image/jpeg"


def user_photo_key(user_id: uuid.UUID, slot: str, content_type: str) -> str:
    return f"user-photos/{user_id}/{slot}.{extension_for(content_type)}"


def clothing_image_key(item_id: uuid.UUID, content_type: str) -> str:
    return f"clothes/{item_id}/main.{extension_for(content_type)}"


def outfit_reference_key(outfit_id: uuid.UUID, content_type: str) -> str:
    return f"outfits/{outfit_id}/reference.{extension_for(content_type)}"


def try_on_image_key(user_id: uuid.UUID, try_on_id: uuid.UUID) -> str:
    return f"try-ons/{user_id}/{try_on_id}.png"


def saved_look_item_key(saved_look_id: uuid.UUID, category: str, source_key: str) -> str:
    extension = source_key.rsplit(".", 1)[-1]
    return f"saved-looks/{saved_look_id}/{category}.{extension}"


@lru_cache
def _client():
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
        raise NotConfiguredError(
            "Object storage is not configured. Set "
            + ", ".join(missing)
            + " in backend/.env (Railway Storage Bucket credentials)."
        )
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
        region_name=settings.s3_region or "auto",
        config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"}),
    )


def _error_message(exc: Exception, action: str) -> str:
    if isinstance(exc, ClientError):
        error = exc.response.get("Error", {})
        if error.get("Code") == "InvalidAccessKeyId":
            return (
                "S3 credentials were rejected. In Railway → your bucket → Credentials, "
                "copy fresh credentials into backend/.env and restart uvicorn."
            )
        return f"Failed to {action}: {error.get('Message', 'unknown error')}"
    return f"Failed to {action}."


def put_object(key: str, data: bytes, content_type: str) -> None:
    try:
        _client().put_object(
            Bucket=settings.s3_bucket_name, Key=key, Body=data, ContentType=content_type
        )
    except (ClientError, BotoCoreError) as exc:
        raise StorageError(_error_message(exc, f"upload {key}")) from exc


def get_object(key: str) -> bytes:
    try:
        response = _client().get_object(Bucket=settings.s3_bucket_name, Key=key)
        return response["Body"].read()
    except (ClientError, BotoCoreError) as exc:
        raise StorageError(_error_message(exc, f"download {key}")) from exc


def copy_object(source_key: str, destination_key: str) -> None:
    try:
        _client().copy_object(
            Bucket=settings.s3_bucket_name,
            Key=destination_key,
            CopySource={"Bucket": settings.s3_bucket_name, "Key": source_key},
        )
    except (ClientError, BotoCoreError) as exc:
        raise StorageError(_error_message(exc, f"copy {source_key}")) from exc


def delete_object(key: str) -> None:
    try:
        _client().delete_object(Bucket=settings.s3_bucket_name, Key=key)
    except (ClientError, BotoCoreError) as exc:
        raise StorageError(_error_message(exc, f"delete {key}")) from exc


def presigned_url(key: str) -> str:
    return _client().generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket_name, "Key": key},
        ExpiresIn=settings.s3_presign_expiry_seconds,
    )
