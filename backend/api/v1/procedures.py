from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.session import get_db
from backend.schemas.procedure import ProcedureDetailOut, ProcedureOut, StepOut
from backend.services.procedure_service import ProcedureNotFound, get_procedure, list_procedures

router = APIRouter(prefix="/v1/procedures", tags=["procedures"])


@router.get("", response_model=list[ProcedureOut])
async def get_procedures(
    category: str | None = None,
    db: AsyncSession = Depends(get_db),
) -> list[ProcedureOut]:
    return await list_procedures(db, category=category)


@router.get("/{slug}", response_model=ProcedureDetailOut)
async def get_procedure_detail(
    slug: str, db: AsyncSession = Depends(get_db)
) -> ProcedureDetailOut:
    try:
        return await get_procedure(slug, db)
    except ProcedureNotFound:
        raise HTTPException(status_code=404, detail=f"Procedure '{slug}' not found")


@router.get("/{slug}/steps", response_model=list[StepOut])
async def get_procedure_steps(
    slug: str, db: AsyncSession = Depends(get_db)
) -> list[StepOut]:
    try:
        return (await get_procedure(slug, db)).steps
    except ProcedureNotFound:
        raise HTTPException(status_code=404, detail=f"Procedure '{slug}' not found")
