FROM python:3.13-slim

WORKDIR /app

COPY pyproject.toml README.md ./
COPY backend/ ./backend/
COPY alembic.ini ./
COPY alembic/ ./alembic/

RUN pip install --no-cache-dir -e .

EXPOSE 8000
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
