from typing import Annotated

from fastapi import Depends, Header, HTTPException

from app.config import settings


def require_admin(
    x_admin_key: Annotated[str | None, Header()] = None,
) -> None:
    if not settings.admin_api_key:
        raise HTTPException(
            status_code=503,
            detail="Admin API is not configured. Set ADMIN_API_KEY in backend/.env.",
        )
    if x_admin_key is None or x_admin_key != settings.admin_api_key:
        raise HTTPException(status_code=401, detail="Invalid or missing admin key.")


RequireAdmin = Annotated[None, Depends(require_admin)]
