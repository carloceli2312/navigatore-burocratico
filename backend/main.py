from fastapi import FastAPI

from backend.api.v1.procedures import router as procedures_router

app = FastAPI(title="Navigatore Burocratico API")

app.include_router(procedures_router)


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
