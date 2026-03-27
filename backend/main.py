from fastapi import FastAPI

from backend.api.v1.auth import router as auth_router
from backend.api.v1.chat import router as chat_router
from backend.api.v1.procedures import router as procedures_router
from backend.api.v1.progress import router as progress_router

app = FastAPI(title="Navigatore Burocratico API")

app.include_router(procedures_router)
app.include_router(chat_router)
app.include_router(auth_router)
app.include_router(progress_router)


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
