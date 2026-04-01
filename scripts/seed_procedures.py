"""Seed procedure data from JSON files into the database.

Usage:
    python -m scripts.seed_procedures

Idempotent: existing procedures are replaced (delete + insert by slug).
"""

import asyncio
import json
import sys
from pathlib import Path

from sqlalchemy import delete, select

sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.db.session import AsyncSessionLocal
from backend.models.procedure import Document, Procedure, Step

DATA_DIR = Path(__file__).parent.parent / "data" / "procedures" / "calabria" / "cosenza"


async def seed() -> None:
    files = sorted(DATA_DIR.glob("*.json"))
    if not files:
        print(f"No JSON files found in {DATA_DIR}")
        return

    async with AsyncSessionLocal() as session:
        for path in files:
            with path.open(encoding="utf-8") as f:
                data = json.load(f)

            slug = data["slug"]

            # Delete existing procedure (cascade removes steps + documents)
            existing = await session.execute(select(Procedure).where(Procedure.slug == slug))
            if existing.scalar_one_or_none():
                await session.execute(delete(Procedure).where(Procedure.slug == slug))
                print(f"  replaced: {slug}")
            else:
                print(f"  inserting: {slug}")

            procedure = Procedure(
                slug=slug,
                name=data["name"],
                category=data["category"],
                description=data["description"],
                ente_competente=data["ente_competente"],
                tags=data["tags"],
                tempo_stimato_giorni=data.get("tempo_stimato_giorni"),
                costo_stimato_eur=data.get("costo_stimato_eur"),
                active=True,
            )
            session.add(procedure)
            await session.flush()  # get procedure.id

            for step_data in data.get("steps", []):
                step = Step(
                    procedure_id=procedure.id,
                    order=step_data["order"],
                    title=step_data["title"],
                    description=step_data["description"],
                    ufficio=step_data.get("ufficio"),
                    costo_stimato_eur=step_data.get("costo_stimato_eur"),
                    tempo_stimato_giorni=step_data.get("tempo_stimato_giorni"),
                )
                session.add(step)
                await session.flush()  # get step.id

                for doc_data in step_data.get("documents", []):
                    session.add(Document(
                        step_id=step.id,
                        name=doc_data["name"],
                        required=doc_data.get("required", True),
                        notes=doc_data.get("notes"),
                    ))

        await session.commit()
        print(f"\nDone. Seeded {len(files)} procedure(s).")


if __name__ == "__main__":
    asyncio.run(seed())
