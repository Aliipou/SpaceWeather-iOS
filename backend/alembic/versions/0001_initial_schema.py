"""Initial schema: users, favorites, refresh_tokens, search_history

Revision ID: 0001
Revises:
Create Date: 2026-04-23
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=True),
        sa.Column("avatar_url", sa.Text, nullable=True),
        sa.Column("bio", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="1"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("token_hash", sa.String(255), nullable=False, unique=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked", sa.Boolean, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_refresh_tokens_token_hash", "refresh_tokens", ["token_hash"])
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])

    op.create_table(
        "favorites",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("apod_date", sa.String(10), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("url", sa.Text, nullable=False),
        sa.Column("hd_url", sa.Text, nullable=True),
        sa.Column("explanation", sa.Text, nullable=False),
        sa.Column("media_type", sa.String(20), nullable=False),
        sa.Column("copyright", sa.String(200), nullable=True),
        sa.Column("saved_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "apod_date", name="uq_user_apod"),
    )
    op.create_index("ix_favorites_user_id", "favorites", ["user_id"])
    op.create_index("ix_favorites_apod_date", "favorites", ["apod_date"])

    op.create_table(
        "search_history",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("query", sa.String(500), nullable=False),
        sa.Column("result_type", sa.String(20), nullable=False),
        sa.Column("result_date", sa.String(10), nullable=True),
        sa.Column("searched_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_history_user_id_searched_at", "search_history", ["user_id", "searched_at"])


def downgrade() -> None:
    op.drop_table("search_history")
    op.drop_table("favorites")
    op.drop_table("refresh_tokens")
    op.drop_table("users")
