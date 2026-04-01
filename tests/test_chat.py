from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from backend.main import app


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


def _mock_ollama(reply: str = "Risposta di test."):
    return patch(
        "backend.services.ai_service._call_ollama",
        new=AsyncMock(return_value={"message": {"role": "assistant", "content": reply}}),
    )


async def test_chat_basic(client):
    with _mock_ollama("Per presentare la SCIA devi..."):
        async with client as c:
            response = await c.post("/v1/chat", json={"message": "Come presento la SCIA?"})
    assert response.status_code == 200
    assert response.json()["reply"] == "Per presentare la SCIA devi..."


async def test_chat_with_procedure_slug(seeded_client):
    with _mock_ollama("La SCIA edilizia richiede...") as mock:
        response = await seeded_client.post(
            "/v1/chat",
            json={
                "message": "Quali documenti servono?",
                "procedure_slug": "scia-edilizia-cosenza",
            },
        )
    assert response.status_code == 200
    # verify that the system prompt was enriched with procedure context
    called_payload = mock.call_args[0][0]
    system_msg = called_payload["messages"][0]["content"]
    assert "SCIA Edilizia" in system_msg


async def test_chat_unknown_procedure_slug(seeded_client):
    """Unknown slug is silently ignored — base system prompt is used."""
    with _mock_ollama("Non conosco quella procedura."):
        response = await seeded_client.post(
            "/v1/chat",
            json={"message": "Cosa devo fare?", "procedure_slug": "procedura-inesistente"},
        )
    assert response.status_code == 200


async def test_chat_ollama_unavailable(client):
    from backend.services.ai_service import OllamaError

    with patch(
        "backend.services.ai_service._call_ollama",
        new=AsyncMock(side_effect=OllamaError("Servizio AI non disponibile al momento.")),
    ):
        async with client as c:
            response = await c.post("/v1/chat", json={"message": "Test"})
    assert response.status_code == 503
    assert "non disponibile" in response.json()["detail"]


async def test_chat_rate_limited(client):
    with patch("backend.api.v1.chat.check_rate_limit", return_value=False):
        async with client as c:
            response = await c.post("/v1/chat", json={"message": "Test"})
    assert response.status_code == 429


async def test_chat_empty_message(client):
    async with client as c:
        response = await c.post("/v1/chat", json={"message": ""})
    assert response.status_code == 422


async def test_chat_message_too_long(client):
    async with client as c:
        response = await c.post("/v1/chat", json={"message": "x" * 1001})
    assert response.status_code == 422
