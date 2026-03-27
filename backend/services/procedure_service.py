import json
from pathlib import Path

from backend.schemas.procedure import ProcedureDetailOut, ProcedureOut

DATA_DIR = Path(__file__).parent.parent.parent / "data" / "procedures" / "calabria" / "cosenza"


class ProcedureNotFound(Exception):
    pass


def _load_all() -> list[dict]:
    procedures = []
    for path in sorted(DATA_DIR.glob("*.json")):
        with path.open(encoding="utf-8") as f:
            procedures.append(json.load(f))
    return procedures


def list_procedures() -> list[ProcedureOut]:
    return [ProcedureOut(**p) for p in _load_all()]


def get_procedure(slug: str) -> ProcedureDetailOut:
    for p in _load_all():
        if p["slug"] == slug:
            return ProcedureDetailOut(**p)
    raise ProcedureNotFound(slug)
