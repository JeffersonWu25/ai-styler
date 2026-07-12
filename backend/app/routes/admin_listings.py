import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import Response
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps.admin_auth import require_admin
from app.db.session import get_db
from app.schemas.listing import ListingCreateFields, ListingResponse
from app.services.listings import (
    ListingError,
    create_listing,
    delete_listing,
    get_listing,
    list_listings,
    parse_price,
)
from app.services.object_storage import ObjectStorageError, download_listing_image

router = APIRouter(
    prefix="/admin/listings",
    tags=["admin-listings"],
    dependencies=[Depends(require_admin)],
)

MAX_IMAGE_BYTES = 15 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "application/octet-stream"}


@router.get("", response_model=list[ListingResponse])
async def get_listings(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ListingResponse]:
    listings = await list_listings(db)
    return [_to_response(listing) for listing in listings]


@router.post("", response_model=ListingResponse, status_code=201)
async def post_listing(
    db: Annotated[AsyncSession, Depends(get_db)],
    title: Annotated[str, Form()],
    brand: Annotated[str, Form()],
    url: Annotated[str, Form()],
    image: UploadFile = File(...),
    price: Annotated[str | None, Form()] = None,
    currency: Annotated[str, Form()] = "USD",
    category: Annotated[str | None, Form()] = None,
) -> ListingResponse:
    try:
        fields = ListingCreateFields(
            title=title,
            brand=brand,
            url=url,
            price=parse_price(price),
            currency=currency or "USD",
            category=category or None,
        )
    except (ValidationError, ListingError) as exc:
        detail = (
            str(exc)
            if isinstance(exc, ListingError)
            else "; ".join(e["msg"] for e in exc.errors())
        )
        raise HTTPException(status_code=400, detail=detail) from exc

    if not fields.title.strip() or not fields.brand.strip():
        raise HTTPException(status_code=400, detail="title and brand are required.")

    image_bytes = await _read_image(image)
    content_type = image.content_type or "image/jpeg"

    try:
        listing = await create_listing(
            db,
            title=fields.title,
            brand=fields.brand,
            url=str(fields.url),
            price=fields.price,
            currency=fields.currency,
            category=fields.category,
            image_bytes=image_bytes,
            content_type=content_type,
        )
    except ListingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return _to_response(listing)


@router.get("/{listing_id}", response_model=ListingResponse)
async def get_listing_detail(
    listing_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ListingResponse:
    listing = await get_listing(db, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Listing not found.")
    return _to_response(listing)


@router.get("/{listing_id}/image")
async def get_listing_image(
    listing_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> Response:
    listing = await get_listing(db, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Listing not found.")

    try:
        image_bytes = download_listing_image(listing.image_object_key)
    except ObjectStorageError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    media_type = "image/jpeg"
    if listing.image_object_key.endswith(".png"):
        media_type = "image/png"
    elif listing.image_object_key.endswith(".webp"):
        media_type = "image/webp"

    return Response(content=image_bytes, media_type=media_type)


@router.delete("/{listing_id}", status_code=204)
async def remove_listing(
    listing_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    try:
        deleted = await delete_listing(db, listing_id)
    except ListingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    if not deleted:
        raise HTTPException(status_code=404, detail="Listing not found.")


async def _read_image(upload: UploadFile) -> bytes:
    if upload.content_type and upload.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail="image must be a JPEG, PNG, or WebP.",
        )

    data = await upload.read()
    if not data:
        raise HTTPException(status_code=400, detail="image is empty.")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="image is too large (max 15 MB).")
    return data


def _to_response(listing) -> ListingResponse:
    return ListingResponse(
        id=str(listing.id),
        title=listing.title,
        brand=listing.brand,
        url=listing.url,
        price=listing.price,
        currency=listing.currency,
        category=listing.category,
        created_at=listing.created_at,
    )
