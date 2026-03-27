"""create procedures, steps, documents tables

Revision ID: b1c2d3e4f5a6
Revises: a1b2c3d4e5f6
Create Date: 2026-03-27 00:01:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b1c2d3e4f5a6"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "procedures",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("slug", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("category", sa.String(length=100), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("ente_competente", sa.String(length=200), nullable=False),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column("tempo_stimato_giorni", sa.Integer(), nullable=True),
        sa.Column("costo_stimato_eur", sa.Float(), nullable=True),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_procedures_slug", "procedures", ["slug"])

    op.create_table(
        "steps",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("procedure_id", sa.Integer(), nullable=False),
        sa.Column("order", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("ufficio", sa.String(length=200), nullable=True),
        sa.Column("costo_stimato_eur", sa.Float(), nullable=True),
        sa.Column("tempo_stimato_giorni", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["procedure_id"], ["procedures.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "documents",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("step_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=300), nullable=False),
        sa.Column("required", sa.Boolean(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["step_id"], ["steps.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("documents")
    op.drop_table("steps")
    op.drop_index("ix_procedures_slug", table_name="procedures")
    op.drop_table("procedures")
