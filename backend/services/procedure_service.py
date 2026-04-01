from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.models.procedure import Procedure, Step
from backend.schemas.procedure import DocumentOut, ProcedureDetailOut, ProcedureOut, StepOut


class ProcedureNotFound(Exception):
    pass


def _to_detail(p: Procedure) -> ProcedureDetailOut:
    return ProcedureDetailOut(
        slug=p.slug,
        name=p.name,
        category=p.category,
        description=p.description,
        ente_competente=p.ente_competente,
        tags=p.tags,
        tempo_stimato_giorni=p.tempo_stimato_giorni,
        costo_stimato_eur=p.costo_stimato_eur,
        steps=[
            StepOut(
                order=s.order,
                title=s.title,
                description=s.description,
                ufficio=s.ufficio,
                costo_stimato_eur=s.costo_stimato_eur,
                tempo_stimato_giorni=s.tempo_stimato_giorni,
                documents=[
                    DocumentOut(name=d.name, required=d.required, notes=d.notes)
                    for d in s.documents
                ],
            )
            for s in p.steps
        ],
    )


async def list_procedures(db: AsyncSession, category: str | None = None) -> list[ProcedureOut]:
    query = select(Procedure).where(Procedure.active == True)  # noqa: E712
    if category:
        query = query.where(Procedure.category == category)
    result = await db.execute(query.order_by(Procedure.id))
    return [
        ProcedureOut(
            slug=p.slug,
            name=p.name,
            category=p.category,
            description=p.description,
            ente_competente=p.ente_competente,
            tags=p.tags,
            tempo_stimato_giorni=p.tempo_stimato_giorni,
            costo_stimato_eur=p.costo_stimato_eur,
        )
        for p in result.scalars()
    ]


async def get_procedure(slug: str, db: AsyncSession) -> ProcedureDetailOut:
    result = await db.execute(
        select(Procedure)
        .where(Procedure.slug == slug, Procedure.active == True)  # noqa: E712
        .options(selectinload(Procedure.steps).selectinload(Step.documents))
    )
    procedure = result.scalar_one_or_none()
    if procedure is None:
        raise ProcedureNotFound(slug)
    return _to_detail(procedure)
