# Navigatore Burocratico

Mobile-first application that guides Italian citizens and professionals through bureaucratic procedures step by step.

**MVP scope**: Calabria region, Province of Cosenza.

## Stack

- **Backend**: Python 3.13 / FastAPI / SQLAlchemy / Alembic
- **Mobile**: Flutter (iOS + Android)

## Getting started

### Backend (Docker)

```bash
# Copy and fill in environment variables
cp .env.example .env  # POSTGRES_PASSWORD is required

# Start the backend and database
docker compose up --build

# Apply database migrations (required on first run or after schema changes)
docker compose exec backend alembic upgrade head
```

Verify the backend is up: `http://localhost:8000/health` should return `{"status":"ok"}`.

> **Note**: Ollama must be running separately for the AI chat feature. Set `OLLAMA_BASE_URL` and `OLLAMA_MODEL` in `.env` accordingly.

### Mobile (Flutter)

**Android emulator** — tunnel the port so the emulator can reach the host:

```bash
adb reverse tcp:8000 tcp:8000
flutter run
```

**Physical device** — the device must be on the same Wi-Fi network as the host. On Windows, allow inbound connections on port 8000 (run once in PowerShell as Administrator):

```powershell
New-NetFirewallRule -DisplayName "Docker Backend 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
```

Then find your PC's local IP (`ipconfig`) and run:

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000
```

### Backend without Docker

```bash
# Install dependencies (with dev extras)
pip install -e ".[dev]"

# Run the development server
uvicorn backend.main:app --reload
```

## Project structure

```
navigatore-burocratico/
├── backend/
│   ├── api/v1/        # Route handlers
│   ├── core/          # Config, security, shared utilities
│   ├── db/            # Database session and migrations setup
│   ├── models/        # SQLAlchemy ORM models
│   ├── services/      # Business logic
│   └── main.py        # FastAPI application entry point
├── data/
│   └── procedures/
│       └── calabria/
│           └── cosenza/   # Procedure definitions (JSON/YAML)
├── tests/
└── scripts/
```
