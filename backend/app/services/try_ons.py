import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_or_404
from app.errors import ConflictError, NotFoundError
from app.models import Outfit, PhotoSlot, TryOn, User
from app.services import storage
from app.services.openai_image import InputImage, generate_image
from app.services.prompts import build_try_on_prompt


async def create_try_on(db: AsyncSession, user: User, outfit_id: uuid.UUID) -> tuple[TryOn, str]:
    """Generates the image synchronously. Returns the try-on and the outfit name."""
    outfit = await get_or_404(db, Outfit, outfit_id, "Outfit")
    items = outfit.items
    if not items:
        raise ConflictError("This outfit has no clothing items.")

    missing = [slot.value for slot in PhotoSlot if user.photo_key(slot) is None]
    if missing:
        raise ConflictError(
            f"Missing {', '.join(missing)} photo(s). Upload them before trying on an outfit."
        )

    images = [_input_image(user.photo_key(slot), slot.value) for slot in PhotoSlot] + [
        _input_image(item.image_key, item.category.value) for item in items
    ]

    result_png = await generate_image(images=images, prompt=build_try_on_prompt(items))

    try_on_id = uuid.uuid4()
    image_key = storage.try_on_image_key(user.id, try_on_id)
    storage.put_object(image_key, result_png, "image/png")

    try_on = TryOn(id=try_on_id, user_id=user.id, outfit_id=outfit.id, image_key=image_key)
    db.add(try_on)
    await db.commit()
    return try_on, outfit.name


async def get_user_try_on(db: AsyncSession, user: User, try_on_id: uuid.UUID) -> TryOn:
    try_on = await db.get(TryOn, try_on_id)
    if try_on is None or try_on.user_id != user.id:
        raise NotFoundError("Try-on not found.")
    return try_on


def _input_image(key: str, name: str) -> InputImage:
    content_type = storage.content_type_for(key)
    extension = storage.extension_for(content_type)
    return InputImage(
        filename=f"{name}.{extension}",
        data=storage.get_object(key),
        content_type=content_type,
    )
