# Personal Finance Intelligence

[![CI](https://github.com/Aayush-Ramrakhyani/personal-finance-intelligence/actions/workflows/ci.yml/badge.svg)](https://github.com/Aayush-Ramrakhyani/personal-finance-intelligence/actions/workflows/ci.yml)

An AI-powered personal finance platform with a Flutter mobile app and FastAPI/PostgreSQL backend.
Import bank statements, auto-categorise expenses with rule-based + AI classification, track budgets,
and get conversational financial insights — built with a clean, layered architecture and a
full async backend.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Tech Decisions](#tech-decisions)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
- [Project Structure](#project-structure)
- [Screenshots](#screenshots)
- [License](#license)

---

## Overview

Most people manage finances across multiple bank accounts, apps, and cards — with no single view of
where money is actually going. Personal Finance Intelligence solves this by letting users import
bank statements as CSV, automatically categorising every transaction, tracking budgets per
category, and surfacing insights through a conversational AI assistant.

**Key engineering highlights:**

- Hash-based duplicate detection prevents double-importing transactions across re-uploaded statements
- Rule-based categorisation covers known merchants instantly; AI fallback (GPT-4/Gemini) handles
  edge cases — with the decision cached so the same merchant is never re-classified
- CSV parsing is bank-agnostic: the parser detects column layout automatically across inconsistent
  formats from different banks
- Large imports are processed asynchronously via Celery; the API returns immediately and the client
  polls job status
- Full async stack (FastAPI + asyncpg + SQLAlchemy async) — no thread-blocking under concurrent
  requests

---

## Features

### Bank Statement Import
- CSV import with automatic column-layout detection across major bank formats
- **Hash-based duplicate detection** — transactions already in the database are skipped silently
- Bulk import — upload multiple months at once; each file queued as a background Celery job
- Manual override for any staged transaction before confirming the import

### Expense Categorisation
- Rule-based categorisation across 30+ spending categories
- AI-assisted fallback (GPT-4 / Gemini) for unrecognised merchants — result cached per merchant
- Manual override + category correction
- Merchant normalisation — "SWIGGY ORDER 123456" → "Swiggy"

### Budget Tracking
- Set monthly budgets per category
- Real-time progress bars — spend vs. budget
- Overspend push notifications via Firebase Cloud Messaging
- Configurable carry-forward logic

### Analytics Dashboard
- Monthly spend breakdown by category, merchant, and weekday
- Month-over-month trend charts
- Top spending merchants ranked by total spend
- Savings rate calculation and trend
- Anomaly detection — flags unusually large transactions

### AI Assistant
- Conversational interface powered by GPT-4 / Gemini
- Query in plain language: *"How much did I spend on subscriptions last month?"*
- Proactive weekly insights pushed as notifications
- Context-aware: the assistant has access to the user's actual transaction history

---

## Tech Stack

| Layer              | Technology                                  |
|--------------------|---------------------------------------------|
| Mobile App         | Flutter (iOS + Android), Riverpod           |
| Backend API        | Python 3.11, FastAPI (async)                |
| Database           | PostgreSQL 16 + SQLAlchemy async + Alembic  |
| Caching            | Redis 7                                     |
| Background Jobs    | Celery (Redis broker)                       |
| AI                 | OpenAI GPT-4 / Google Gemini (pluggable)    |
| Push Notifications | Firebase Cloud Messaging                    |
| Infrastructure     | Docker, docker-compose, GitHub Actions      |

---

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                   Flutter Mobile App                    │
│   Import · Dashboard · Budget · AI Chat · Alerts       │
│              State: Riverpod AsyncNotifier              │
└──────────────────────┬─────────────────────────────────┘
                       │ REST API (JWT Bearer)
┌──────────────────────▼─────────────────────────────────┐
│                FastAPI Backend (async)                  │
│  Auth · Import · Categorise · Budget · AI · Analytics  │
│                 Service layer pattern                   │
└──────┬──────────────┬─────────────┬────────────────────┘
       │              │             │
┌──────▼──────┐ ┌─────▼────┐ ┌─────▼──────────┐
│  PostgreSQL  │ │  Redis   │ │  OpenAI/Gemini  │
│ (main store) │ │ Cache +  │ │   (AI chat +    │
│   Alembic    │ │  Broker  │ │  categorisation)│
└─────────────┘ └────┬─────┘ └────────────────┘
                     │
            ┌────────▼────────┐
            │  Celery Workers  │
            │ (CSV processing, │
            │  AI batch jobs)  │
            └─────────────────┘
```

---

## Tech Decisions

**FastAPI over Django**
FastAPI's native async support is the right fit for an I/O-heavy backend (database, Redis, AI API
calls). Pydantic provides request validation automatically. The auto-generated OpenAPI docs at
`/docs` are immediately useful. Django's ORM and admin panel are not needed for an API-only backend.

**Celery for CSV processing**
Parsing and categorising a full bank statement (1,000+ transactions, AI calls per unknown merchant)
can take 20–30 seconds. FastAPI's `BackgroundTasks` runs in-process and would block the event loop
for other requests. Celery workers run out-of-process, scale independently, and retry on failure.

**Redis for caching and broker**
Analytical aggregations (monthly summaries, trend charts) are expensive to recompute on every
dashboard open. Redis caches these per-user with a short TTL. Redis also serves as the Celery
broker — one service, two roles.

**PostgreSQL over NoSQL**
Financial data is inherently relational: users → accounts → transactions → categories → budgets.
SQL aggregations (GROUP BY category, month-over-month comparisons, savings rate) are clean and
performant with proper indexing. The schema is well-defined and stable.

**Riverpod (AsyncNotifier) in Flutter**
Every data operation is async (API calls). AsyncNotifier handles loading/error/data states cleanly
and is straightforward to test by overriding providers in tests — something Provider makes
difficult without mocking.

**AI with rule-based fallback**
Calling GPT-4 for every transaction is slow and expensive. The categoriser runs rule-based matching
first (instant, free); only unrecognised merchants hit the AI. The AI decision is then cached in
the database per merchant name — the same coffee shop is never sent to the API twice.

---

## Getting Started

**Prerequisites:** Docker and docker-compose only. No local Python, PostgreSQL, or Redis needed.

```bash
git clone https://github.com/Aayush-Ramrakhyani/personal-finance-intelligence.git
cd personal-finance-intelligence

# Copy the env template and set your API keys
cp .env.example .env
# Edit .env: set OPENAI_API_KEY or GEMINI_API_KEY, and generate new JWT secrets

# Start the entire stack: API + PostgreSQL + Redis + Celery worker
docker compose up
```

The API is now running at **http://localhost:8000**
Interactive API docs (Swagger UI): **http://localhost:8000/docs**

Apply database migrations:

```bash
docker compose exec backend alembic upgrade head
```

Seed demo data:

```bash
docker compose exec backend python seed.py
```

**Flutter app** (requires Flutter 3.19+):

```bash
cd frontend
flutter pub get
flutter run
```

---

## Running Tests

Tests use an in-memory SQLite database — no external services required.

```bash
cd backend
pip install -r requirements.txt
pytest tests/ -v
```

Current status: **18 tests passing** across auth flows, transaction CRUD, balance integrity,
user isolation, and analytics calculations.

---

## Environment Variables

Copy `.env.example` to `.env`:

```env
# JWT — generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
JWT_SECRET=CHANGE_ME
JWT_REFRESH_SECRET=CHANGE_ME

# AI provider: "openai" or "gemini"
AI_PROVIDER=openai
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...

# Firebase (for push notifications — optional for local dev)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
```

Database and Redis URLs are pre-configured for docker-compose in `docker-compose.yml`. See
`.env.example` for the full list with documentation for every variable.

---

## API Reference

### Auth
| Method | Endpoint                  | Description             |
|--------|---------------------------|-------------------------|
| POST   | `/api/v1/auth/register`   | Register new user       |
| POST   | `/api/v1/auth/login`      | Login, get JWT tokens   |
| POST   | `/api/v1/auth/refresh`    | Refresh access token    |
| GET    | `/api/v1/auth/me`         | Get current user        |

### Transactions
| Method | Endpoint                             | Description                    |
|--------|--------------------------------------|--------------------------------|
| POST   | `/api/v1/transactions`               | Create transaction             |
| GET    | `/api/v1/transactions`               | List (paginated, filterable)   |
| PUT    | `/api/v1/transactions/:id/category`  | Update category                |
| DELETE | `/api/v1/transactions/:id`           | Delete transaction             |

### Import
| Method | Endpoint                        | Description                      |
|--------|---------------------------------|----------------------------------|
| POST   | `/api/v1/imports/upload`        | Upload CSV — returns job ID      |
| GET    | `/api/v1/imports/:job_id`       | Poll import job status           |
| POST   | `/api/v1/imports/:job_id/confirm` | Confirm staged transactions    |

### Analytics
| Method | Endpoint                       | Description                     |
|--------|--------------------------------|---------------------------------|
| GET    | `/api/v1/analytics/overview`   | Monthly income/expense/savings  |
| GET    | `/api/v1/analytics/by-category` | Spend by category              |
| GET    | `/api/v1/analytics/trends`     | Month-over-month trends         |
| GET    | `/api/v1/analytics/merchants`  | Top merchants by spend          |

### Budgets
| Method | Endpoint                  | Description                     |
|--------|---------------------------|---------------------------------|
| GET    | `/api/v1/budgets`         | List all budgets                |
| POST   | `/api/v1/budgets`         | Create or update budget         |
| GET    | `/api/v1/budgets/status`  | Current month budget vs. actual |

### AI Assistant
| Method | Endpoint              | Description                     |
|--------|-----------------------|---------------------------------|
| POST   | `/api/v1/ai/chat`     | Send message, get AI response   |
| GET    | `/api/v1/ai/insights` | Weekly proactive insights       |

Full interactive documentation available at `/docs` when the stack is running.

---

## Project Structure

```
personal-finance-intelligence/
├── backend/
│   ├── app/
│   │   ├── api/v1/           # Route handlers (thin — delegate to services)
│   │   ├── services/         # Business logic
│   │   │   ├── import_service.py      # CSV parsing, dedup, staging
│   │   │   ├── analytics_service.py   # Spend aggregations
│   │   │   ├── budget_service.py      # Budget tracking
│   │   │   └── auth_service.py        # JWT auth
│   │   ├── ai/               # AI provider abstraction
│   │   │   ├── base.py                # Abstract provider interface
│   │   │   ├── openai_provider.py     # OpenAI implementation
│   │   │   ├── gemini_provider.py     # Gemini implementation
│   │   │   ├── factory.py             # Selects provider from env config
│   │   │   ├── categorization_service.py
│   │   │   └── financial_assistant.py
│   │   ├── models/           # SQLAlchemy ORM models
│   │   ├── schemas/          # Pydantic request/response schemas
│   │   ├── tasks/            # Celery background tasks
│   │   │   ├── import_tasks.py        # Async CSV processing
│   │   │   └── analytics_tasks.py     # Scheduled cache refresh
│   │   ├── core/             # Config, security, logging, exceptions
│   │   └── db/               # Async engine, session, repositories
│   ├── tests/
│   │   ├── conftest.py       # In-memory SQLite fixtures, async client
│   │   ├── api/              # Auth endpoint tests, transaction CRUD tests
│   │   └── services/         # Analytics service unit tests
│   ├── migrations/           # Alembic migration scripts
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/                 # Flutter app
│   └── lib/
│       ├── features/         # Feature-first folder structure
│       │   ├── auth/
│       │   ├── dashboard/
│       │   ├── imports/
│       │   ├── budgets/
│       │   ├── transactions/
│       │   ├── analytics/
│       │   └── ai/
│       ├── core/             # Theme, network client, secure storage, utils
│       └── shared/widgets/
│
├── docker-compose.yml        # Full stack: API + PostgreSQL + Redis + Celery worker
├── .env.example              # Documented environment variable template
└── README.md
```

---

## Screenshots

> Add screenshots of: Dashboard · CSV Import flow · Budget tracking · AI assistant chat

---

## License

MIT License.
