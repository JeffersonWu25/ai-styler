from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import database_connect_args, settings

engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args=database_connect_args(
        settings.database_url,
        verify_ssl=settings.database_ssl_verify,
    ),
)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session
