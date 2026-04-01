import json
from pathlib import Path

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

import backend.models  # noqa: F401 — ensures all models are registered with Base.metadata
from backend.db.base import Base
from backend.db.session import get_db
from backend.main import app
from backend.models.procedure import Document, Procedure, Step

_TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
_DATA_DIR = Path(__file__).parent.parent / "data" / "procedures" / "calabria" / "cosenza"


async def _seed_procedures(session: AsyncSession) -> None:
    for path in sorted(_DATA_DIR.glob("*.json")):
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        procedure = Procedure(
            slug=data["slug"],
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
        await session.flush()
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
            await session.flush()
            for doc_data in step_data.get("documents", []):
                session.add(Document(
                    step_id=step.id,
                    name=doc_data["name"],
                    required=doc_data.get("required", True),
                    notes=doc_data.get("notes"),
                ))


def _make_engine_and_factory():
    engine = create_async_engine(_TEST_DB_URL, echo=False)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    return engine, factory


@pytest.fixture
async def auth_client():
    """AsyncClient backed by an isolated in-memory SQLite database."""
    engine, session_factory = _make_engine_and_factory()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async def _override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
    app.dependency_overrides.pop(get_db, None)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture
async def seeded_client():
    """AsyncClient backed by in-memory SQLite pre-populated with procedure data."""
    engine, session_factory = _make_engine_and_factory()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with session_factory() as session:
        await _seed_procedures(session)
        await session.commit()

    async def _override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
    app.dependency_overrides.pop(get_db, None)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()
