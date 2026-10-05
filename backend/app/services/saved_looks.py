import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import ConflictError, NotFoundError
from app.models import Outfit, SavedLook, User
from app.services import storage
from app.services.try_ons import get_user_try_on


async def get_saved_look(db: AsyncSession, user: User, saved_look_id: uuid.UUID) -> SavedLook:
    saved_look = await db.get(SavedLook, saved_look_id)
    if saved_look is None or saved_look.user_id != user.id:
        raise NotFoundError("Saved look not found.")
    return saved_look


async def save_look(
    db: AsyncSession, user: User, try_on_id: uuid.UUID
) -> tuple[SavedLook, bool]:
    """Returns (saved_look, created). Saving the same try-on twice returns the existing look."""
    try_on = await get_user_try_on(db, user, try_on_id)

    existing = await db.scalar(select(SavedLook).where(SavedLook.try_on_id == try_on.id))
    if existing is not None:
        return existing, False

    outfit = await db.get(Outfit, try_on.outfit_id) if try_on.outfit_id else None
    if outfit is None:
        raise ConflictError("The outfit for this try-on no longer exists.")

    saved_look_id = uuid.uuid4()
    copied_keys: list[str] = []
    snapshot_items = []
    for item in outfit.items:
        key = storage.saved_look_item_key(saved_look_id, item.category.value, item.image_key)
        storage.copy_object(item.image_key, key)
        copied_keys.append(key)
        snapshot_items.append(
            {
                "category": item.category.value,
                "name": item.name,
                "brand": item.brand,
                "listing_url": item.listing_url,
                "image_key": key,
            }
        )

    saved_look = SavedLook(
        id=saved_look_id,
        user_id=user.id,
        try_on_id=try_on.id,
        image_key=try_on.image_key,
        outfit_snapshot={"name": outfit.name, "items": snapshot_items},
    )
    db.add(saved_look)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        for key in copied_keys:
            storage.delete_object(key)
        raise
    return saved_look, True


async def delete_saved_look(db: AsyncSession, user: User, saved_look_id: uuid.UUID) -> None:
    saved_look = await get_saved_look(db, user, saved_look_id)
    item_keys = [item["image_key"] for item in saved_look.outfit_snapshot["items"]]
    await db.delete(saved_look)
    await db.commit()
    for key in item_keys:
        storage.delete_object(key)
