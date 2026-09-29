from typing import Annotated

from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import SEED_USER_ID, User


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    user = await db.get(User, SEED_USER_ID)
    if user is None:
        raise HTTPException(
            status_code=500,
            detail="Seed user is missing. Insert the development user before calling this API.",
        )
    return user
