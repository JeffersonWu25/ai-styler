import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Form, UploadFile
from pydantic import HttpUrl
from sqlalchemy import select

from app.db.session import get_or_404
from app.deps.admin_auth import require_admin
from app.deps.auth import DbSession
from app.errors import BadRequestError
from app.models import ClothingCategory, ClothingItem
from app.schemas.clothes import ClothingItemResponse
from app.services import storage
from app.services.uploads import read_image

router = APIRouter(
    prefix="/admin/clothes",
    tags=["admin"],
    dependencies=[Depends(require_admin)],
)


@router.get("", response_model=list[ClothingItemResponse])
async def list_clothes(db: DbSession) -> list[ClothingItemResponse]:
    result = await db.scalars(select(ClothingItem).order_by(ClothingItem.created_at.desc()))
    return [ClothingItemResponse.from_model(item) for item in result]


@router.post("", response_model=ClothingItemResponse, status_code=201)
async def create_clothing_item(
    db: DbSession,
    category: Annotated[ClothingCategory, Form()],
    name: Annotated[str, Form()],
    brand: Annotated[str, Form()],
    listing_url: Annotated[HttpUrl, Form(alias="listingUrl")],
    image: UploadFile,
) -> ClothingItemResponse:
    if not name.strip() or not brand.strip():
        raise BadRequestError("name and brand are required.")
    upload = await read_image(image, "image")

    item_id = uuid.uuid4()
    key = storage.clothing_image_key(item_id, upload.content_type)
    storage.put_object(key, upload.data, upload.content_type)

    item = ClothingItem(
        id=item_id,
        category=category,
        name=name.strip(),
        brand=brand.strip(),
        listing_url=str(listing_url),
        image_key=key,
    )
    db.add(item)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        storage.delete_object(key)
        raise
    return ClothingItemResponse.from_model(item)


@router.get("/{item_id}", response_model=ClothingItemResponse)
async def get_clothing_item(item_id: uuid.UUID, db: DbSession) -> ClothingItemResponse:
    return ClothingItemResponse.from_model(
        await get_or_404(db, ClothingItem, item_id, "Clothing item")
    )


@router.delete("/{item_id}", status_code=204)
async def delete_clothing_item(item_id: uuid.UUID, db: DbSession) -> None:
    item = await get_or_404(db, ClothingItem, item_id, "Clothing item")
    await db.delete(item)
    await db.commit()
    storage.delete_object(item.image_key)
