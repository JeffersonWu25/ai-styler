from dataclasses import dataclass

from fastapi import UploadFile

from app.errors import BadRequestError

MAX_IMAGE_BYTES = 15 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


@dataclass(frozen=True)
class ImageUpload:
    data: bytes
    content_type: str


async def read_image(upload: UploadFile, field_name: str) -> ImageUpload:
    content_type = upload.content_type or "image/jpeg"
    if content_type == "application/octet-stream":
        content_type = "image/jpeg"
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise BadRequestError(f"{field_name} must be a JPEG, PNG, or WebP image.")

    data = await upload.read()
    if not data:
        raise BadRequestError(f"{field_name} image is empty.")
    if len(data) > MAX_IMAGE_BYTES:
        raise BadRequestError(f"{field_name} image is too large (max 15 MB).")
    return ImageUpload(data=data, content_type=content_type)
