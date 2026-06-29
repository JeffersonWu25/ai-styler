from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import database_connect_args, settings
from app.db.base import Base

engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args=database_connect_args(
        settings.database_url,
        verify_ssl=settings.database_ssl_verify,
    ),
)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)


async def init_db() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session
