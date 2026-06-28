import base64

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.catalog.outfits import get_outfit
from app.config import settings
from app.services.openai_image import OpenAIImageError, generate_try_on

router = APIRouter(prefix="/try-on", tags=["try-on"])

MAX_IMAGE_BYTES = 15 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "application/octet-stream"}


@router.post("")
async def try_on(
    front: UploadFile = File(...),
    side: UploadFile = File(...),
    back: UploadFile = File(...),
) -> dict[str, str]:
    front_bytes = await _read_image(front, "front")
    await _read_image(side, "side")
    await _read_image(back, "back")

    try:
        outfit = get_outfit(settings.default_outfit_id)
        garment_paths = outfit.garment_paths()
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except KeyError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    front_filename = front.filename or "front.jpg"

    try:
        result_bytes = await generate_try_on(
            user_front_image=front_bytes,
            user_front_filename=front_filename,
            garment_paths=garment_paths,
            prompt=outfit.prompt,
        )
    except OpenAIImageError as exc:
        status_code = exc.status_code or 502
        if status_code == 401:
            status_code = 500
        raise HTTPException(status_code=status_code, detail=str(exc)) from exc

    return {
        "imageBase64": base64.b64encode(result_bytes).decode("ascii"),
        "outfitName": outfit.name,
    }


async def _read_image(upload: UploadFile, field_name: str) -> bytes:
    if upload.content_type and upload.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"{field_name} must be a JPEG, PNG, or WebP image.",
        )

    data = await upload.read()
    if not data:
        raise HTTPException(status_code=400, detail=f"{field_name} image is empty.")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"{field_name} image is too large (max 15 MB).",
        )
    return data
