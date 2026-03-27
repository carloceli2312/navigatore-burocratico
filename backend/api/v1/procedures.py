from fastapi import APIRouter, HTTPException

from backend.schemas.procedure import ProcedureDetailOut, ProcedureOut, StepOut
from backend.services.procedure_service import ProcedureNotFound, get_procedure, list_procedures

router = APIRouter(prefix="/v1/procedures", tags=["procedures"])


@router.get("", response_model=list[ProcedureOut])
async def get_procedures() -> list[ProcedureOut]:
    return list_procedures()


@router.get("/{slug}", response_model=ProcedureDetailOut)
async def get_procedure_detail(slug: str) -> ProcedureDetailOut:
    try:
        return get_procedure(slug)
    except ProcedureNotFound:
        raise HTTPException(status_code=404, detail=f"Procedure '{slug}' not found")


@router.get("/{slug}/steps", response_model=list[StepOut])
async def get_procedure_steps(slug: str) -> list[StepOut]:
    try:
        return get_procedure(slug).steps
    except ProcedureNotFound:
        raise HTTPException(status_code=404, detail=f"Procedure '{slug}' not found")
