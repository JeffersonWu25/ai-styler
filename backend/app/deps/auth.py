from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.errors import AppError
from app.models.user import SEED_USER_ID, User

DbSession = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(db: DbSession) -> User:
    user = await db.get(User, SEED_USER_ID)
    if user is None:
        raise AppError(
            "Seed user is missing. Insert the development user before calling this API."
        )
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
