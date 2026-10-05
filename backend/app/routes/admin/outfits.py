import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_or_404
from app.deps.admin_auth import require_admin
from app.deps.auth import DbSession
from app.errors import BadRequestError
from app.models import ClothingCategory, ClothingItem, Outfit
from app.schemas.outfit import OutfitResponse
from app.services import storage
from app.services.uploads import read_image

router = APIRouter(
    prefix="/admin/outfits",
    tags=["admin"],
    dependencies=[Depends(require_admin)],
)


@router.get("", response_model=list[OutfitResponse])
async def list_outfits(db: DbSession) -> list[OutfitResponse]:
    result = await db.scalars(select(Outfit).order_by(Outfit.created_at.desc()))
    return [OutfitResponse.from_model(outfit) for outfit in result]


@router.post("", response_model=OutfitResponse, status_code=201)
async def create_outfit(
    db: DbSession,
    name: Annotated[str, Form()],
    shirt_id: Annotated[uuid.UUID | None, Form(alias="shirtId")] = None,
    bottom_id: Annotated[uuid.UUID | None, Form(alias="bottomId")] = None,
    outerwear_id: Annotated[uuid.UUID | None, Form(alias="outerwearId")] = None,
    shoe_id: Annotated[uuid.UUID | None, Form(alias="shoeId")] = None,
    reference_image: Annotated[UploadFile | None, File(alias="referenceImage")] = None,
) -> OutfitResponse:
    if not name.strip():
        raise BadRequestError("name is required.")
    if not any((shirt_id, bottom_id, outerwear_id, shoe_id)):
        raise BadRequestError("An outfit needs at least one clothing item.")

    outfit = Outfit(
        id=uuid.uuid4(),
        name=name.strip(),
        shirt_id=await _check_item(db, shirt_id, ClothingCategory.SHIRT),
        bottom_id=await _check_item(db, bottom_id, ClothingCategory.BOTTOM),
        outerwear_id=await _check_item(db, outerwear_id, ClothingCategory.OUTERWEAR),
        shoe_id=await _check_item(db, shoe_id, ClothingCategory.SHOE),
    )
    if reference_image is not None:
        upload = await read_image(reference_image, "referenceImage")
        outfit.reference_image_key = storage.outfit_reference_key(outfit.id, upload.content_type)
        storage.put_object(outfit.reference_image_key, upload.data, upload.content_type)

    db.add(outfit)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        if outfit.reference_image_key:
            storage.delete_object(outfit.reference_image_key)
        raise

    # Reload so the item relationships are populated for the response.
    result = await db.scalars(
        select(Outfit).where(Outfit.id == outfit.id).execution_options(populate_existing=True)
    )
    return OutfitResponse.from_model(result.one())


@router.get("/{outfit_id}", response_model=OutfitResponse)
async def get_outfit(outfit_id: uuid.UUID, db: DbSession) -> OutfitResponse:
    return OutfitResponse.from_model(await get_or_404(db, Outfit, outfit_id, "Outfit"))


@router.delete("/{outfit_id}", status_code=204)
async def delete_outfit(outfit_id: uuid.UUID, db: DbSession) -> None:
    outfit = await get_or_404(db, Outfit, outfit_id, "Outfit")
    await db.delete(outfit)
    await db.commit()
    if outfit.reference_image_key:
        storage.delete_object(outfit.reference_image_key)


async def _check_item(
    db: AsyncSession, item_id: uuid.UUID | None, category: ClothingCategory
) -> uuid.UUID | None:
    if item_id is None:
        return None
    item = await db.get(ClothingItem, item_id)
    if item is None:
        raise BadRequestError(f"{category.value}Id does not match any clothing item.")
    if item.category != category:
        raise BadRequestError(
            f"{category.value}Id points to a {item.category.value}, not a {category.value}."
        )
    return item.id
