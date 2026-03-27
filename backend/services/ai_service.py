import httpx

from backend.core.config import settings
from backend.services.procedure_service import ProcedureNotFound, get_procedure

_SYSTEM_PROMPT = """Sei un assistente specializzato nelle procedure burocratiche italiane, \
per la Provincia di Cosenza, Regione Calabria.

Rispondi in modo chiaro e conciso. Rispondi SOLO a domande relative a burocrazia, \
documenti necessari, uffici competenti, scadenze, costi e iter amministrativi.

Se non sei certo di un'informazione, dì esplicitamente che non ne sei sicuro e invita \
il cittadino a verificare direttamente presso l'ufficio competente o il sito istituzionale. \
Non inventare mai dati normativi, importi o requisiti specifici.

Rispondi sempre in italiano."""


class OllamaError(Exception):
    pass


async def _call_ollama(payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            response = await client.post(
                f"{settings.ollama_base_url}/api/chat",
                json=payload,
            )
            response.raise_for_status()
            return response.json()
        except httpx.ConnectError as exc:
            raise OllamaError("Servizio AI non disponibile al momento.") from exc
        except httpx.TimeoutException as exc:
            raise OllamaError("Il servizio AI ha impiegato troppo tempo a rispondere.") from exc
        except httpx.HTTPStatusError as exc:
            raise OllamaError(
                f"Errore dal servizio AI: {exc.response.status_code}"
            ) from exc


def _build_system_prompt(procedure_slug: str | None) -> str:
    if not procedure_slug:
        return _SYSTEM_PROMPT

    try:
        proc = get_procedure(procedure_slug)
    except ProcedureNotFound:
        return _SYSTEM_PROMPT

    context = (
        f"\n\nIl cittadino sta seguendo la procedura: **{proc.name}**\n"
        f"Descrizione: {proc.description}\n"
        f"Ente competente: {proc.ente_competente}\n"
        f"Tempo stimato: {proc.tempo_stimato_giorni} giorni\n"
        f"Costo stimato: {proc.costo_stimato_eur} €\n\n"
        f"Usa queste informazioni per rispondere in modo contestuale."
    )
    return _SYSTEM_PROMPT + context


async def ask(message: str, procedure_slug: str | None = None) -> str:
    system_prompt = _build_system_prompt(procedure_slug)
    payload = {
        "model": settings.ollama_model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message},
        ],
        "stream": False,
    }
    data = await _call_ollama(payload)
    return data["message"]["content"]
