from sqlalchemy import JSON, Boolean, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.db.base import Base


class Procedure(Base):
    __tablename__ = "procedures"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    ente_competente: Mapped[str] = mapped_column(String(200), nullable=False)
    tags: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    tempo_stimato_giorni: Mapped[int | None] = mapped_column(Integer, nullable=True)
    costo_stimato_eur: Mapped[float | None] = mapped_column(Float, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    steps: Mapped[list["Step"]] = relationship(
        "Step", back_populates="procedure", order_by="Step.order", cascade="all, delete-orphan"
    )


class Step(Base):
    __tablename__ = "steps"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    procedure_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("procedures.id", ondelete="CASCADE"), nullable=False
    )
    order: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    ufficio: Mapped[str | None] = mapped_column(String(200), nullable=True)
    costo_stimato_eur: Mapped[float | None] = mapped_column(Float, nullable=True)
    tempo_stimato_giorni: Mapped[int | None] = mapped_column(Integer, nullable=True)

    procedure: Mapped["Procedure"] = relationship("Procedure", back_populates="steps")
    documents: Mapped[list["Document"]] = relationship(
        "Document", back_populates="step", order_by="Document.id", cascade="all, delete-orphan"
    )


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    step_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("steps.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(300), nullable=False)
    required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    step: Mapped["Step"] = relationship("Step", back_populates="documents")
