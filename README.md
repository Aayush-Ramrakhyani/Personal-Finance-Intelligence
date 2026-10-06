# Personal Finance Intelligence System

A full-stack personal finance application with AI-powered insights — built with FastAPI (Python) on the backend and Flutter on the frontend.

## Architecture

```
backend/          FastAPI + SQLAlchemy 2.0 async + PostgreSQL
frontend/         Flutter + Riverpod + GoRouter
docker-compose    PostgreSQL 16 + Redis 7 + Celery worker
```

**Design principles:**
- Financially correct first, AI-powered second — all numbers are computed deterministically by the backend; AI only explains
- India-focused: INR (₹), Asia/Kolkata timezone, Indian merchant categorization
- User isolation enforced at every query (`user_id` from JWT, never from request body)
- No floats for money — `NUMERIC(15,2)` in PostgreSQL throughout

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Flutter SDK ≥ 3.24
- Python 3.11+ (for local backend dev without Docker)

### 1. Clone and configure

```bash
git clone <repo>
cd personal-finance-intelligence
cp .env.example .env
# Edit .env — set JWT_SECRET, AI_PROVIDER, and API keys
```

### 2. Start with Docker

```bash
docker-compose up -d
```

The API will be available at `http://localhost:8000`.

### 3. Run migrations and seed demo data

```bash
docker-compose exec backend alembic upgrade head
docker-compose exec backend python seed.py
```

Demo credentials: `demo@finance.local` / `Demo@1234`

### 4. Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

## Backend

### Local development (without Docker)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
pip install -r requirements.txt --prefer-binary
alembic upgrade head
uvicorn app.main:app --reload
```

### Run tests

```bash
cd backend
pytest tests/ -v
```

### API reference

All endpoints under `/api/v1/`. Interactive docs at `http://localhost:8000/docs`.

| Group | Endpoints |
|-------|-----------|
| Auth | POST /auth/register, /auth/login, /auth/refresh, GET /auth/me |
| Accounts | GET/POST /accounts, GET/PATCH/DELETE /accounts/{id} |
| Transactions | GET/POST /transactions, POST /transfers, GET/PATCH/DELETE /transactions/{id} |
| Categories | GET/POST /categories, PATCH/DELETE /categories/{id} |
| Budgets | GET/POST /budgets, GET/PATCH/DELETE /budgets/{id} |
| Analytics | GET /analytics/overview, /categories, /cash-flow, /trends, /anomalies |
| Imports | POST /imports, GET /imports/{id}/columns, POST /imports/{id}/preview, POST /imports/{id}/confirm |
| Recurring | GET /recurring, POST /recurring/{id}/confirm, DELETE /recurring/{id} |
| AI | GET/POST /ai/conversations, POST /ai/conversations/{id}/messages, GET/POST /ai/insights |
| Reports | GET /reports/monthly |

## AI Integration

Supports OpenAI (GPT-4o-mini) and Google Gemini. Set in `.env`:

```env
AI_PROVIDER=openai        # or gemini
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

**Safety model:** AI never queries the database directly. The assistant parses user intent, the backend fetches verified numbers, then AI generates the natural language explanation. AI never invents financial figures.

## Environment Variables

See `.env.example` for the full list. Minimum required:

```env
DATABASE_URL=postgresql+asyncpg://finance:finance@localhost:5432/finance_db
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=<random-256-bit>
JWT_REFRESH_SECRET=<random-256-bit>
AI_PROVIDER=openai
OPENAI_API_KEY=sk-...
```

## Project Structure

```
backend/
  app/
    api/v1/endpoints/   Route handlers (thin — delegate to services)
    services/           Business logic layer
    db/repositories/    Data access layer (SQLAlchemy 2.0 async)
    models/             SQLAlchemy ORM models
    schemas/            Pydantic v2 request/response schemas
    ai/                 AI provider abstraction + financial assistant
    core/               Config, security, exceptions
  migrations/           Alembic async migrations
  tests/                pytest suite (SQLite in-memory)

frontend/
  lib/
    core/               Theme, constants, network client, storage
    features/           Feature modules (auth, dashboard, transactions, ...)
    routing/            GoRouter configuration
    shared/             Shared widgets
```

## Transfer Accounting

Transfers create two linked transactions (both `type=transfer`) connected via a `Transfer` record. Analytics endpoints filter transfers out via `WHERE transfer_id IS NULL`, so they never distort income/expense totals.

## CSV Import

Supports bank statement CSV files. The import wizard auto-detects date, amount, description, and merchant columns using regex patterns. Duplicate detection uses multi-factor scoring (exact reference match = 100%, same account + amount + date ±1 day = 90% confidence).
