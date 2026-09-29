import uuid

from sqlalchemy import String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

SEED_USER_ID = uuid.UUID("d21bf82d-306d-4bcc-b4ac-905d2736443f")


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True)
    username: Mapped[str] = mapped_column(String(255), unique=True)
    front_photo = mapped_column(String(512), nullable=True)
    side_photo = mapped_column(String(512), nullable=True)
    back_photo = mapped_column(String(512), nullable=True)
