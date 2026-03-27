from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

from backend.core.rate_limit import check_rate_limit
from backend.services.ai_service import OllamaError, ask

router = APIRouter(prefix="/v1/chat", tags=["chat"])


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    procedure_slug: str | None = None


class ChatResponse(BaseModel):
    reply: str


@router.post("", response_model=ChatResponse)
async def chat(request: Request, body: ChatRequest) -> ChatResponse:
    client_ip = request.client.host if request.client else "unknown"
    if not check_rate_limit(client_ip):
        raise HTTPException(status_code=429, detail="Troppe richieste. Riprova tra un minuto.")

    try:
        reply = await ask(body.message, body.procedure_slug)
    except OllamaError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return ChatResponse(reply=reply)
