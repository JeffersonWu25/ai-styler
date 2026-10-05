from datetime import datetime, timezone

from sqlalchemy import DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def created_at_column() -> Mapped[datetime]:
    return mapped_column(
        DateTime(timezone=True), default=utcnow, server_default=func.now()
    )
