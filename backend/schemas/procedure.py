from pydantic import BaseModel


class DocumentOut(BaseModel):
    name: str
    required: bool
    notes: str | None


class StepOut(BaseModel):
    order: int
    title: str
    description: str
    ufficio: str | None
    costo_stimato_eur: float | None
    tempo_stimato_giorni: int | None
    documents: list[DocumentOut]


class ProcedureOut(BaseModel):
    slug: str
    name: str
    category: str
    description: str
    ente_competente: str
    tags: list[str]
    tempo_stimato_giorni: int | None
    costo_stimato_eur: float | None


class ProcedureDetailOut(ProcedureOut):
    steps: list[StepOut]
