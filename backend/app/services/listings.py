import uuid
from decimal import Decimal, InvalidOperation

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.listing import Listing
from app.services.object_storage import (
    ObjectStorageError,
    delete_listing_image,
    upload_listing_image,
)


class ListingError(Exception):
    pass


async def create_listing(
    db: AsyncSession,
    *,
    title: str,
    brand: str,
    url: str,
    price: Decimal | None,
    currency: str,
    category: str | None,
    image_bytes: bytes,
    content_type: str,
) -> Listing:
    listing_id = uuid.uuid4()
    try:
        object_key = upload_listing_image(listing_id, image_bytes, content_type)
    except ObjectStorageError as exc:
        raise ListingError(str(exc)) from exc

    listing = Listing(
        id=listing_id,
        title=title.strip(),
        brand=brand.strip(),
        url=str(url).strip(),
        price=price,
        currency=currency.strip().upper() or "USD",
        category=category.strip() if category else None,
        image_object_key=object_key,
    )
    db.add(listing)
    try:
        await db.commit()
        await db.refresh(listing)
    except Exception:
        await db.rollback()
        try:
            delete_listing_image(object_key)
        except ObjectStorageError:
            pass
        raise
    return listing


async def list_listings(db: AsyncSession) -> list[Listing]:
    result = await db.execute(select(Listing).order_by(Listing.created_at.desc()))
    return list(result.scalars().all())


async def get_listing(db: AsyncSession, listing_id: uuid.UUID) -> Listing | None:
    result = await db.execute(select(Listing).where(Listing.id == listing_id))
    return result.scalar_one_or_none()


async def delete_listing(db: AsyncSession, listing_id: uuid.UUID) -> bool:
    listing = await get_listing(db, listing_id)
    if listing is None:
        return False

    object_key = listing.image_object_key
    await db.delete(listing)
    await db.commit()

    try:
        delete_listing_image(object_key)
    except ObjectStorageError as exc:
        raise ListingError(str(exc)) from exc
    return True


def parse_price(raw: str | None) -> Decimal | None:
    if raw is None or not raw.strip():
        return None
    try:
        value = Decimal(raw.strip())
    except InvalidOperation as exc:
        raise ListingError("price must be a valid number.") from exc
    if value < 0:
        raise ListingError("price cannot be negative.")
    return value
