"""Rename generated_outfits to try_ons, store object keys, add saved_looks.

Revision ID: 0002_try_ons_saved_looks
Revises: 0001_initial
Create Date: 2026-09-29

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002_try_ons_saved_looks"
down_revision: Union[str, Sequence[str], None] = "0001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

PHOTO_SLOTS = ("front", "side", "back")


def _created_at() -> sa.Column:
    return sa.Column(
        "created_at",
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
        nullable=False,
    )


def upgrade() -> None:
    for slot in PHOTO_SLOTS:
        op.alter_column("users", f"{slot}_photo", new_column_name=f"{slot}_photo_key")

    op.alter_column("clothes", "item_name", new_column_name="name")
    op.alter_column("clothes", "image_url", new_column_name="image_key")
    op.add_column("clothes", _created_at())

    op.alter_column("outfits", "outfit_name", new_column_name="name")
    op.alter_column("outfits", "reference_image_url", new_column_name="reference_image_key")
    op.add_column("outfits", _created_at())

    op.rename_table("generated_outfits", "try_ons")
    op.execute("ALTER TABLE try_ons RENAME CONSTRAINT generated_outfits_pkey TO try_ons_pkey")
    op.execute(
        "ALTER TABLE try_ons RENAME CONSTRAINT generated_outfits_user_id_fkey "
        "TO try_ons_user_id_fkey"
    )
    op.execute("ALTER INDEX ix_generated_outfits_user_id RENAME TO ix_try_ons_user_id")
    op.execute("ALTER INDEX ix_generated_outfits_outfit_id RENAME TO ix_try_ons_outfit_id")
    op.alter_column("try_ons", "generated_image_url", new_column_name="image_key")
    op.add_column("try_ons", _created_at())

    op.drop_constraint("generated_outfits_outfit_id_fkey", "try_ons", type_="foreignkey")
    op.alter_column("try_ons", "outfit_id", nullable=True)
    op.create_foreign_key(
        "try_ons_outfit_id_fkey",
        "try_ons",
        "outfits",
        ["outfit_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.create_table(
        "saved_looks",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("try_on_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("image_key", sa.String(length=512), nullable=False),
        sa.Column("outfit_snapshot", postgresql.JSONB(), nullable=False),
        _created_at(),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["try_on_id"], ["try_ons.id"], ondelete="SET NULL"),
        sa.UniqueConstraint("try_on_id"),
    )
    op.create_index("ix_saved_looks_user_id", "saved_looks", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_saved_looks_user_id", table_name="saved_looks")
    op.drop_table("saved_looks")

    op.drop_constraint("try_ons_outfit_id_fkey", "try_ons", type_="foreignkey")
    op.execute("DELETE FROM try_ons WHERE outfit_id IS NULL")
    op.alter_column("try_ons", "outfit_id", nullable=False)
    op.create_foreign_key(
        "generated_outfits_outfit_id_fkey", "try_ons", "outfits", ["outfit_id"], ["id"]
    )
    op.drop_column("try_ons", "created_at")
    op.alter_column("try_ons", "image_key", new_column_name="generated_image_url")
    op.execute("ALTER INDEX ix_try_ons_outfit_id RENAME TO ix_generated_outfits_outfit_id")
    op.execute("ALTER INDEX ix_try_ons_user_id RENAME TO ix_generated_outfits_user_id")
    op.execute(
        "ALTER TABLE try_ons RENAME CONSTRAINT try_ons_user_id_fkey "
        "TO generated_outfits_user_id_fkey"
    )
    op.execute("ALTER TABLE try_ons RENAME CONSTRAINT try_ons_pkey TO generated_outfits_pkey")
    op.rename_table("try_ons", "generated_outfits")

    op.drop_column("outfits", "created_at")
    op.alter_column("outfits", "reference_image_key", new_column_name="reference_image_url")
    op.alter_column("outfits", "name", new_column_name="outfit_name")

    op.drop_column("clothes", "created_at")
    op.alter_column("clothes", "image_key", new_column_name="image_url")
    op.alter_column("clothes", "name", new_column_name="item_name")

    for slot in PHOTO_SLOTS:
        op.alter_column("users", f"{slot}_photo_key", new_column_name=f"{slot}_photo")
