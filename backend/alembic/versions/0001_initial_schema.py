"""Initial schema for users, clothes, outfits, and generated outfits.

Revision ID: 0001_initial
Revises:
Create Date: 2026-09-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001_initial"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

clothing_category = sa.Enum(
    "shirt",
    "bottom",
    "outerwear",
    "shoe",
    name="clothing_category",
)


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("username", sa.String(length=255), nullable=False),
        sa.Column("front_photo", sa.String(length=512), nullable=True),
        sa.Column("side_photo", sa.String(length=512), nullable=True),
        sa.Column("back_photo", sa.String(length=512), nullable=True),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("username"),
    )

    op.create_table(
        "clothes",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("category", clothing_category, nullable=False),
        sa.Column("item_name", sa.Text(), nullable=False),
        sa.Column("listing_url", sa.Text(), nullable=False),
        sa.Column("brand", sa.Text(), nullable=False),
        sa.Column("image_url", sa.String(length=512), nullable=False),
    )

    op.create_table(
        "outfits",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("outfit_name", sa.Text(), nullable=False),
        sa.Column("shirt_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("bottom_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("outerwear_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("shoe_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("reference_image_url", sa.String(length=512), nullable=True),
        sa.ForeignKeyConstraint(["shirt_id"], ["clothes.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["bottom_id"], ["clothes.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["outerwear_id"], ["clothes.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["shoe_id"], ["clothes.id"], ondelete="SET NULL"),
    )

    op.create_table(
        "generated_outfits",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("outfit_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("generated_image_url", sa.String(length=512), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["outfit_id"], ["outfits.id"]),
    )
    op.create_index("ix_generated_outfits_user_id", "generated_outfits", ["user_id"])
    op.create_index("ix_generated_outfits_outfit_id", "generated_outfits", ["outfit_id"])


def downgrade() -> None:
    op.drop_index("ix_generated_outfits_outfit_id", table_name="generated_outfits")
    op.drop_index("ix_generated_outfits_user_id", table_name="generated_outfits")
    op.drop_table("generated_outfits")
    op.drop_table("outfits")
    op.drop_table("clothes")
    op.drop_table("users")
    clothing_category.drop(op.get_bind(), checkfirst=True)
