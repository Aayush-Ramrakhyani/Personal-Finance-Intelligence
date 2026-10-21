# Personal Finance Intelligence

[![CI](https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence/actions/workflows/ci.yml/badge.svg)](https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence/actions/workflows/ci.yml)

An AI-powered personal finance platform with a **Flutter mobile app**, a **Next.js web dashboard**, and a **FastAPI/PostgreSQL backend**. Import bank statements, auto-categorise expenses with rule-based + AI classification, track budgets, and get conversational financial insights — built with a clean, layered architecture and a full async backend.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Tech Decisions](#tech-decisions)
- [Getting Started](#getting-started)
  - [Backend (Docker)](#backend-docker)
  - [Web Dashboard](#web-dashboard)
  - [Flutter App](#flutter-app)
- [Running Tests](#running-tests)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
- [Project Structure](#project-structure)
- [Screenshots](#screenshots)
- [License](#license)

---

## Overview

Most people manage finances across multiple bank accounts, apps, and cards — with no single view of where money is actually going. Personal Finance Intelligence solves this by letting users import bank statements as CSV, automatically categorising every transaction, tracking budgets per category, and surfacing insights through a conversational AI assistant.

The platform ships as three independent clients sharing a single backend:

| Client | Platform | Status |
|--------|----------|--------|
| **Flutter app** | iOS + Android | In development (Play Store target) |
| **Next.js web dashboard** | Browser | Complete — 15 pages, full API integration |
| **FastAPI backend** | Docker | Complete — async, tested, documented |

**Key engineering highlights:**

- Hash-based duplicate detection prevents double-importing transactions across re-uploaded statements
- Rule-based categorisation covers known merchants instantly; AI fallback (GPT-4/Gemini) handles edge cases — with the decision cached so the same merchant is never re-classified
- CSV parsing is bank-agnostic: the parser detects column layout automatically across inconsistent formats from different Indian banks
- Full async stack (FastAPI + asyncpg + SQLAlchemy async) — no thread-blocking under concurrent requests
- Web dashboard features spring-physics animations throughout (Framer Motion), count-up number transitions, animated charts, and a shared-layout navigation indicator

---

## Features

### Bank Statement Import
- CSV import with automatic column-layout detection across major bank formats
- **Hash-based duplicate detection** — transactions already in the database are skipped silently
- 4-step guided import flow (upload → detect columns → preview → confirm)
- Manual override for any staged transaction before confirming the import

### Expense Categorisation
- Rule-based categorisation across 30+ spending categories
- AI-assisted fallback (GPT-4 / Gemini) for unrecognised merchants — result cached per merchant
- Manual override + category correction
- Merchant normalisation — "SWIGGY ORDER 123456" → "Swiggy"

### Budget Tracking
- Set monthly budgets per category
- Real-time progress bars — spend vs. budget with circular progress rings
- Overspend push notifications via Firebase Cloud Messaging
- Configurable carry-forward logic

### Analytics Dashboard
- Monthly spend breakdown by category, merchant, and time range (3/6/12 months)
- Month-over-month trend charts (income vs. expenses, net cash flow line)
- Savings rate calculation and trend
- Anomaly detection — flags categories with unusually high spend vs. historical average

### AI Assistant
- Conversational interface powered by GPT-4 / Gemini
- Query in plain language: *"How much did I spend on subscriptions last month?"*
- Proactive weekly insights pushed as notifications
- Context-aware: the assistant has access to the user's actual transaction history
- Typing indicator with animated 3-dot bounce (web)

### Web Dashboard (new)
- 15-page Next.js app: landing, auth, dashboard, transactions, CSV import, budgets, analytics, AI chat, notifications, settings, 404
- Premium dark theme with INR formatting (₹, lakh compact notation)
- Framer Motion spring physics throughout — page transitions, staggered card entrances, count-up numbers, animated charts, progress rings
- JWT authentication with automatic token refresh on 401
- Fully wired to the real FastAPI backend — no mock data

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Web Dashboard** | Next.js 16 (App Router), TypeScript strict, Tailwind CSS v4, Framer Motion, Recharts |
| **Mobile App** | Flutter (iOS + Android), Riverpod, GoRouter, Clean Architecture |
| **Backend API** | Python 3.11+, FastAPI (async), Pydantic v2 |
| **Database** | PostgreSQL 16 + SQLAlchemy async + Alembic |
| **Caching** | Redis 7 |
| **Background Jobs** | Celery (Redis broker) |
| **AI** | OpenAI GPT-4o-mini / Google Gemini 1.5 (pluggable) |
| **Push Notifications** | Firebase Cloud Messaging |
| **Infrastructure** | Docker, docker-compose, GitHub Actions |

---

## Architecture

```
┌──────────────────────┐   ┌─────────────────────────────┐
│   Flutter Mobile App │   │     Next.js Web Dashboard    │
│  iOS + Android       │   │  15 pages · dark theme       │
│  Riverpod · GoRouter │   │  Framer Motion · Recharts    │
└──────────┬───────────┘   └──────────────┬──────────────┘
           │                              │
           └────────────┬─────────────────┘
                        │ REST API  (JWT Bearer)
           ┌────────────▼──────────────────────┐
           │       FastAPI Backend (async)      │
           │  Auth · Import · Categorise        │
           │  Budget · AI · Analytics           │
           │       Service layer pattern        │
           └──────┬────────────┬───────────────┘
                  │            │
      ┌───────────▼──┐  ┌──────▼──────┐  ┌─────────────────┐
      │  PostgreSQL  │  │   Redis 7   │  │  OpenAI/Gemini   │
      │  (main store)│  │  Cache +    │  │  AI chat +       │
      │  Alembic     │  │  Broker     │  │  categorisation  │
      └──────────────┘  └──────┬──────┘  └─────────────────┘
                               │
                      ┌────────▼────────┐
                      │  Celery Workers  │
                      │  CSV processing  │
                      │  AI batch jobs   │
                      └─────────────────┘
```

---

## Tech Decisions

**Next.js App Router for the web client**
The App Router's route groups allow clean separation between the auth shell (`(auth)`) and the app shell `(app)` — different layouts, redirects, and loading states per group. Server Components handle metadata; all interactive pages are client components with real-time data fetching.

**Tailwind CSS v4 (CSS-first config)**
v4 uses `@theme {}` directives in CSS instead of `tailwind.config.js`. All design tokens are CSS custom properties (`var(--color-accent)` etc.) — this makes Recharts chart styling trivial since chart props accept `var(...)` strings directly.

**Framer Motion for animation**
Spring physics (`stiffness`, `damping`, `mass`) produce natural-feeling motion vs. hand-coded CSS transitions. `layoutId` shared-layout makes the sidebar active indicator slide between nav items without any position calculation. `AnimatePresence` handles mount/unmount — critical for dialogs, page transitions, and the CSV import step transitions.

**FastAPI over Django**
FastAPI's native async support is the right fit for an I/O-heavy backend (database, Redis, AI API calls). Pydantic provides request validation automatically. Django's ORM and admin panel are not needed for an API-only backend.

**Celery for CSV processing**
Parsing and categorising a full bank statement (1,000+ transactions, AI calls per unknown merchant) can take 20–30 seconds. Celery workers run out-of-process, scale independently, and retry on failure.

**Redis for caching and broker**
Analytical aggregations (monthly summaries, trend charts) are expensive to recompute on every dashboard open. Redis caches these per-user with a short TTL, and also serves as the Celery broker — one service, two roles.

**PostgreSQL over NoSQL**
Financial data is inherently relational. SQL aggregations (GROUP BY category, month-over-month comparisons, savings rate) are clean and performant with proper indexing. The schema is stable and well-defined.

**Riverpod (AsyncNotifier) in Flutter**
Every data operation is async (API calls). AsyncNotifier handles loading/error/data states cleanly and is testable by overriding providers in tests.

**AI with rule-based fallback**
Calling GPT-4 for every transaction is slow and expensive. The categoriser runs rule-based matching first (instant, free); only unrecognised merchants hit the AI. The AI decision is then cached per merchant name.

---

## Getting Started

### Backend (Docker)

**Prerequisites:** Docker Desktop only. No local Python, PostgreSQL, or Redis needed.

```bash
git clone https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence.git
cd Personal-Finance-Intelligence

# Copy the env template
cp .env.example .env

# Edit .env — set at minimum:
#   JWT_SECRET=<random 32+ char string>
#   JWT_REFRESH_SECRET=<random 32+ char string>
#   OPENAI_API_KEY=<your key>   (leave blank to disable AI chat)
# Generate secrets with: python -c "import secrets; print(secrets.token_urlsafe(32))"

# Start the full stack: API + PostgreSQL + Redis + Celery worker
docker compose up -d

# Apply database migrations (first time only)
docker compose exec backend alembic upgrade head

# Optional: seed demo data
docker compose exec backend python seed.py
```

| Service | URL |
|---------|-----|
| Backend API | http://localhost:8000 |
| Swagger UI (interactive docs) | http://localhost:8000/docs |

---

### Web Dashboard

Requires Node.js 18+. The backend must be running first.

```bash
cd web

# Install dependencies
npm install

# Create local env file
cp .env.local.example .env.local
# .env.local already points to http://localhost:8000/api/v1 — no changes needed for local dev

# Start dev server
npm run dev
```

Open **http://localhost:3000** — register an account, then explore the full dashboard.

```bash
# Production build (optional — verifies TypeScript + all 15 routes)
npm run build
```

**Pages:**

| Route | Page |
|-------|------|
| `/` | Landing page |
| `/login` | Sign in |
| `/register` | Create account |
| `/dashboard` | Overview — income, expenses, savings, charts |
| `/transactions` | Paginated transaction list with filters |
| `/transactions/[id]` | Transaction detail + edit/delete |
| `/import` | 4-step CSV import flow |
| `/budgets` | Budget management with progress rings |
| `/analytics` | Charts, trends, anomaly detection |
| `/ai` | AI assistant chat |
| `/notifications` | Notification centre |
| `/settings` | Profile + security |

---

### Flutter App

Requires Flutter 3.19+.

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

Current status: **18 tests passing** across auth flows, transaction CRUD, balance integrity, user isolation, and analytics calculations.

---

## Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```env
# JWT — generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
JWT_SECRET=CHANGE_ME
JWT_REFRESH_SECRET=CHANGE_ME

# AI provider: "openai" or "gemini"
AI_PROVIDER=openai
OPENAI_API_KEY=sk-...      # leave blank to disable AI features
GEMINI_API_KEY=...         # alternative to OpenAI

# Firebase (for push notifications — optional for local dev)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
```

Database, Redis, and Celery URLs are pre-configured for docker-compose in `docker-compose.yml` — they use internal service names and do not need to be changed. See `.env.example` for the full list with documentation for every variable.

---

## API Reference

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login, get JWT tokens |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/auth/me` | Get current user |

### Transactions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/transactions` | List (paginated, filterable) |
| POST | `/api/v1/transactions` | Create transaction |
| GET | `/api/v1/transactions/:id` | Get transaction detail |
| PATCH | `/api/v1/transactions/:id` | Update transaction |
| DELETE | `/api/v1/transactions/:id` | Delete transaction |

### Import
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/imports/upload` | Upload CSV |
| GET | `/api/v1/imports/:job_id` | Get import job status |
| POST | `/api/v1/imports/:job_id/detect-columns` | Detect column layout |
| POST | `/api/v1/imports/:job_id/preview` | Preview staged transactions |
| POST | `/api/v1/imports/:job_id/confirm` | Confirm import |

### Analytics
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/analytics/overview` | Monthly income/expense/savings |
| GET | `/api/v1/analytics/categories` | Spend by category |
| GET | `/api/v1/analytics/cash-flow` | Monthly cash flow |
| GET | `/api/v1/analytics/trends` | Month-over-month trends |
| GET | `/api/v1/analytics/anomalies` | Spending anomalies |

### Budgets
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/budgets` | List all budgets |
| POST | `/api/v1/budgets` | Create budget |
| PUT | `/api/v1/budgets/:id` | Update budget |
| DELETE | `/api/v1/budgets/:id` | Delete budget |

### AI Assistant
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/ai/conversations` | List conversations |
| POST | `/api/v1/ai/conversations` | Create conversation |
| GET | `/api/v1/ai/conversations/:id` | Get conversation |
| POST | `/api/v1/ai/conversations/:id/messages` | Send message |
| GET | `/api/v1/ai/insights` | Get AI insights |
| POST | `/api/v1/ai/insights/generate` | Generate new insights |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notifications` | List notifications |
| GET | `/api/v1/notifications/unread-count` | Unread count |
| POST | `/api/v1/notifications/:id/read` | Mark as read |
| POST | `/api/v1/notifications/mark-all-read` | Mark all read |

Full interactive documentation available at **http://localhost:8000/docs** when the stack is running.

---

## Project Structure

```
personal-finance-intelligence/
│
├── backend/                        # FastAPI async API
│   ├── app/
│   │   ├── api/v1/                 # Route handlers (thin — delegate to services)
│   │   ├── services/               # Business logic
│   │   │   ├── import_service.py   # CSV parsing, dedup, staging
│   │   │   ├── analytics_service.py
│   │   │   ├── budget_service.py
│   │   │   └── auth_service.py
│   │   ├── ai/                     # AI provider abstraction
│   │   │   ├── base.py             # Abstract provider interface
│   │   │   ├── openai_provider.py
│   │   │   ├── gemini_provider.py
│   │   │   ├── factory.py          # Selects provider from env config
│   │   │   ├── categorization_service.py
│   │   │   └── financial_assistant.py
│   │   ├── models/                 # SQLAlchemy ORM models
│   │   ├── schemas/                # Pydantic request/response schemas
│   │   ├── tasks/                  # Celery background tasks
│   │   ├── core/                   # Config, security, logging, exceptions
│   │   └── db/                     # Async engine, session, repositories
│   ├── tests/
│   ├── migrations/                 # Alembic migration scripts
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/                       # Flutter mobile app
│   └── lib/
│       ├── features/               # Feature-first folder structure
│       │   ├── auth/
│       │   ├── dashboard/
│       │   ├── imports/
│       │   ├── budgets/
│       │   ├── transactions/
│       │   ├── analytics/
│       │   └── ai/
│       ├── core/                   # Theme, network client, secure storage, utils
│       └── shared/widgets/
│
├── web/                            # Next.js web dashboard
│   ├── app/
│   │   ├── (auth)/                 # Auth route group (login, register)
│   │   │   ├── login/page.tsx
│   │   │   └── register/page.tsx
│   │   ├── (app)/                  # App route group (sidebar + topbar shell)
│   │   │   ├── dashboard/page.tsx
│   │   │   ├── transactions/
│   │   │   ├── import/page.tsx
│   │   │   ├── budgets/page.tsx
│   │   │   ├── analytics/page.tsx
│   │   │   ├── ai/page.tsx
│   │   │   ├── notifications/page.tsx
│   │   │   └── settings/page.tsx
│   │   ├── page.tsx                # Landing page
│   │   ├── not-found.tsx           # 404
│   │   ├── globals.css             # Tailwind v4 design system (@theme tokens)
│   │   └── layout.tsx
│   ├── components/
│   │   ├── layout/                 # Sidebar (animated width, layoutId nav), Topbar
│   │   ├── motion/                 # AnimatedNumber, PageTransition, Stagger
│   │   └── ui/                     # Button, Card, Dialog, Input, Progress, Skeleton, Badge
│   ├── contexts/auth.tsx           # JWT auth context + auto-refresh
│   ├── lib/
│   │   ├── api/                    # One file per resource (auth, transactions, …)
│   │   ├── motion.ts               # Spring presets, shared variants
│   │   └── utils.ts                # cn(), formatCurrency (INR/lakh), formatDate
│   └── types/index.ts              # All TypeScript types matching backend schemas
│
├── docker-compose.yml              # Full stack: API + PostgreSQL + Redis + Celery
├── .env.example                    # Documented environment variable template
└── README.md
```

---

## Screenshots

> Add screenshots of: Landing page · Dashboard · CSV Import flow · Budget tracking · AI assistant chat

---

## License

This is a personal project by **Aayush Ramrakhyani**. All rights reserved.
