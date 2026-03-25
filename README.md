# Navigatore Burocratico

Mobile-first application that guides Italian citizens and professionals through bureaucratic procedures step by step.

**MVP scope**: Calabria region, Province of Cosenza.

## Stack

- **Backend**: Python 3.13 / FastAPI / SQLAlchemy / Alembic
- **Mobile**: Flutter (iOS + Android)

## Getting started

```bash
# Copy and fill in environment variables
cp .env.example .env

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
