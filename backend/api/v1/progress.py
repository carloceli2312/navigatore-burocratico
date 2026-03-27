from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.deps import get_current_user
from backend.db.session import get_db
from backend.models.user import User, UserProgress

router = APIRouter(prefix="/v1/progress", tags=["progress"])


# ── schemas ──────────────────────────────────────────────────────────────────


class ProgressIn(BaseModel):
    completed_steps: list[int]


class ProgressOut(BaseModel):
    procedure_slug: str
    completed_steps: list[int]
    started_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)


# ── routes ───────────────────────────────────────────────────────────────────


@router.get("/{procedure_slug}", response_model=ProgressOut)
async def get_progress(
    procedure_slug: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> UserProgress:
    result = await db.execute(
        select(UserProgress).where(
            UserProgress.user_id == user.id,
            UserProgress.procedure_slug == procedure_slug,
        )
    )
    progress = result.scalar_one_or_none()
    if not progress:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nessun progresso trovato per questa procedura.",
        )
    return progress


@router.put("/{procedure_slug}", response_model=ProgressOut)
async def update_progress(
    procedure_slug: str,
    body: ProgressIn,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> UserProgress:
    result = await db.execute(
        select(UserProgress).where(
            UserProgress.user_id == user.id,
            UserProgress.procedure_slug == procedure_slug,
        )
    )
    progress = result.scalar_one_or_none()
    if progress:
        progress.completed_steps = body.completed_steps
        progress.updated_at = datetime.now(timezone.utc)
    else:
        progress = UserProgress(
            user_id=user.id,
            procedure_slug=procedure_slug,
            completed_steps=body.completed_steps,
        )
        db.add(progress)
    await db.commit()
    await db.refresh(progress)
    return progress
