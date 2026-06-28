import base64
from pathlib import Path

import httpx

from app.config import settings

OPENAI_IMAGES_EDITS_URL = "https://api.openai.com/v1/images/edits"


class OpenAIImageError(Exception):
    def __init__(self, message: str, status_code: int | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code


async def generate_try_on(
    *,
    user_front_image: bytes,
    user_front_filename: str,
    garment_paths: list[Path],
    prompt: str,
) -> bytes:
    if not settings.openai_api_key:
        raise OpenAIImageError("OPENAI_API_KEY is not configured on the server.")

    files: list[tuple[str, tuple[str, bytes, str]]] = [
        (
            "image[]",
            (
                user_front_filename,
                user_front_image,
                _content_type(user_front_filename),
            ),
        ),
    ]

    for garment_path in garment_paths:
        garment_bytes = garment_path.read_bytes()
        files.append(
            (
                "image[]",
                (
                    garment_path.name,
                    garment_bytes,
                    _content_type(garment_path.name),
                ),
            )
        )

    data = {
        "model": settings.openai_image_model,
        "prompt": prompt,
        "size": settings.openai_image_size,
        "quality": settings.openai_image_quality,
    }

    headers = {"Authorization": f"Bearer {settings.openai_api_key}"}

    timeout = httpx.Timeout(connect=30.0, read=300.0, write=60.0, pool=30.0)

    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(
            OPENAI_IMAGES_EDITS_URL,
            headers=headers,
            data=data,
            files=files,
        )

    if response.status_code >= 400:
        detail = response.text
        try:
            payload = response.json()
            if isinstance(payload, dict) and "error" in payload:
                error = payload["error"]
                if isinstance(error, dict):
                    detail = error.get("message", detail)
        except Exception:
            pass
        raise OpenAIImageError(detail, status_code=response.status_code)

    payload = response.json()
    try:
        image_b64 = payload["data"][0]["b64_json"]
    except (KeyError, IndexError, TypeError) as exc:
        raise OpenAIImageError("OpenAI returned an unexpected response format.") from exc

    return base64.b64decode(image_b64)


def _content_type(filename: str) -> str:
    lower = filename.lower()
    if lower.endswith(".png"):
        return "image/png"
    if lower.endswith(".webp"):
        return "image/webp"
    return "image/jpeg"
