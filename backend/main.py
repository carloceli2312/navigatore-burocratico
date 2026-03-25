from fastapi import FastAPI

app = FastAPI(title="Navigatore Burocratico API")


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
