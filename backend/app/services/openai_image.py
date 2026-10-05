import base64
from dataclasses import dataclass

import httpx

from app.config import settings
from app.errors import AppError, NotConfiguredError, UpstreamError

OPENAI_IMAGES_EDITS_URL = "https://api.openai.com/v1/images/edits"


@dataclass(frozen=True)
class InputImage:
    filename: str
    data: bytes
    content_type: str


async def generate_image(*, images: list[InputImage], prompt: str) -> bytes:
    if not settings.openai_api_key:
        raise NotConfiguredError("OPENAI_API_KEY is not configured on the server.")

    files = [
        ("image[]", (image.filename, image.data, image.content_type)) for image in images
    ]
    data = {
        "model": settings.openai_image_model,
        "prompt": prompt,
        "size": settings.openai_image_size,
        "quality": settings.openai_image_quality,
    }
    headers = {"Authorization": f"Bearer {settings.openai_api_key}"}
    timeout = httpx.Timeout(connect=30.0, read=300.0, write=60.0, pool=30.0)

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                OPENAI_IMAGES_EDITS_URL, headers=headers, data=data, files=files
            )
    except httpx.HTTPError as exc:
        raise UpstreamError(f"Could not reach OpenAI: {exc}") from exc

    if response.status_code >= 400:
        raise _error_from_response(response)

    try:
        return base64.b64decode(response.json()["data"][0]["b64_json"])
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        raise UpstreamError("OpenAI returned an unexpected response format.") from exc


def _error_from_response(response: httpx.Response) -> AppError:
    detail = response.text
    try:
        payload = response.json()
    except ValueError:
        payload = None
    if isinstance(payload, dict) and isinstance(payload.get("error"), dict):
        detail = payload["error"].get("message", detail)

    # A rejected API key is a server misconfiguration, not the client's fault.
    if response.status_code == 401:
        return AppError(detail, status_code=500)
    if response.status_code >= 500:
        return UpstreamError(detail)
    return AppError(detail, status_code=response.status_code)
