<div align="center">

# 💰 Personal Finance Intelligence

### *Your money. Understood. Automatically.*

**AI-powered personal finance platform — import bank statements, auto-categorise every rupee,  
track budgets, and get conversational insights from your own financial data.**

<br/>

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js_16-000000?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis_7-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)

[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://typescriptlang.org)
[![Python](https://img.shields.io/badge/Python_3.11+-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_v4-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white)](https://tailwindcss.com)
[![Framer Motion](https://img.shields.io/badge/Framer_Motion-0055FF?style=flat-square&logo=framer&logoColor=white)](https://framer.com/motion)
[![OpenAI](https://img.shields.io/badge/OpenAI_GPT--4o-412991?style=flat-square&logo=openai&logoColor=white)](https://openai.com)
[![Celery](https://img.shields.io/badge/Celery-37814A?style=flat-square&logo=celery&logoColor=white)](https://docs.celeryq.dev)

<br/>

[**Live Demo**](http://localhost:3000) · [**API Docs**](http://localhost:8000/docs) · [**Report Bug**](https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence/issues) · [**Request Feature**](https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence/issues)

</div>

---

## ✨ What makes this different

> Most finance apps make you enter transactions manually. This one reads your bank statement CSV, figures out what every charge is, and shows you where your money went — automatically.

| | Personal Finance Intelligence |
|---|---|
| 🏦 **Import** | Upload any Indian bank's CSV — columns auto-detected |
| 🤖 **Categorise** | Rule-based for known merchants, GPT-4 fallback for the rest |
| 🔁 **Deduplicate** | Hash-based — re-upload the same file, nothing doubles |
| 📊 **Analyse** | Trends, breakdowns, anomaly detection, savings rate |
| 💬 **Ask questions** | *"How much did I spend on Swiggy last month?"* |
| 📱 **Any device** | Flutter mobile app + Next.js web dashboard |

---

## 🖥️ Three clients, one backend

```
┌─────────────────────┐      ┌──────────────────────────┐
│   Flutter Mobile    │      │    Next.js Web Dashboard  │
│   iOS + Android     │      │    15 pages · dark theme  │
│   Riverpod · Clean  │      │    Spring animations      │
└──────────┬──────────┘      └────────────┬─────────────┘
           │                              │
           └──────────────┬───────────────┘
                          │  JWT Bearer / REST
              ┌───────────▼──────────────┐
              │    FastAPI  (async)       │
              │  Auth · Import · AI       │
              │  Budget · Analytics       │
              └───┬───────────┬──────────┘
                  │           │
         ┌────────▼──┐  ┌─────▼──────┐  ┌──────────────┐
         │ PostgreSQL │  │   Redis    │  │ OpenAI/Gemini │
         │  Alembic   │  │ Cache+Jobs │  │  AI provider  │
         └────────────┘  └─────┬──────┘  └──────────────┘
                               │
                      ┌────────▼────────┐
                      │  Celery Workers  │
                      │  CSV · AI batch  │
                      └─────────────────┘
```

---

## 🚀 Quick Start

> One command gets the entire backend running.

```bash
# 1. Clone
git clone https://github.com/Aayush-Ramrakhyani/Personal-Finance-Intelligence.git
cd Personal-Finance-Intelligence

# 2. Configure (30 seconds)
cp .env.example .env
# Open .env and set JWT_SECRET + JWT_REFRESH_SECRET
# Generate them with: python -c "import secrets; print(secrets.token_urlsafe(32))"

# 3. Launch everything
docker compose up -d
docker compose exec backend alembic upgrade head
```

**That's it.** PostgreSQL + Redis + FastAPI + Celery worker — all running.

| Service | URL |
|---------|-----|
| 🌐 Web Dashboard | http://localhost:3000 |
| ⚡ API | http://localhost:8000 |
| 📖 Swagger UI | http://localhost:8000/docs |

---

## 🌐 Web Dashboard

> 15 animated pages. Premium dark theme. Spring physics throughout.

```bash
cd web
npm install
cp .env.local.example .env.local   # already points to localhost:8000
npm run dev
```

Open **http://localhost:3000**, register an account, and start exploring.

<details>
<summary><b>📋 All 15 pages</b></summary>

<br/>

| Route | Page | Highlights |
|-------|------|-----------|
| `/` | Landing | Animated hero, feature grid, tech stack |
| `/login` | Sign in | Staggered form, error pill animations |
| `/register` | Create account | Client-side validation, smooth transitions |
| `/dashboard` | Overview | Count-up numbers, area chart, budget rings |
| `/transactions` | Transaction list | Debounced search, animated filter panel |
| `/transactions/[id]` | Detail view | Edit dialog, delete confirm |
| `/import` | CSV Import | 4-step stepper with directional slide transitions |
| `/budgets` | Budgets | Circular progress rings, CRUD dialogs |
| `/analytics` | Analytics | Bar, line, pie charts — 3/6/12 month range |
| `/ai` | AI Assistant | Typing indicator, conversation history |
| `/notifications` | Notifications | Stagger list, mark-read on click |
| `/settings` | Settings | Profile form, security info |
| `*` | 404 | Animated not-found page |

</details>

<details>
<summary><b>🎨 Animation system</b></summary>

<br/>

Every interaction has a physical feel:

- **Page transitions** — fade + 12px vertical slide, `cubic-bezier(0, 0, 0.2, 1)`
- **Cards** — spring lift on hover (`y: -2`, stiffness 500)
- **Navigation** — `layoutId` shared indicator slides between active items
- **Numbers** — count-up via `requestAnimationFrame` with `easeOutQuart`, triggered by `useInView`
- **Charts** — Recharts built-in `animationDuration` on all series
- **Progress rings** — SVG `strokeDashoffset` animated with spring physics
- **Import stepper** — directional `x` slide per step, `mode="wait"` for clean transitions
- **AI typing** — 3 dots with staggered `y`-bounce
- **Reduced motion** — single CSS media query disables all animations globally

</details>

---

## 📱 Flutter App

```bash
cd frontend
flutter pub get
flutter run          # connects to the same backend at localhost:8000
```

Built with Riverpod (AsyncNotifier), GoRouter, and Clean Architecture feature modules.

---

## ⚙️ Features Deep Dive

<details>
<summary><b>🏦 Bank Statement Import</b></summary>

<br/>

1. **Upload** — drag-and-drop any CSV from HDFC, SBI, ICICI, Axis, Kotak, etc.
2. **Detect** — the parser inspects the file and identifies date, amount, description columns automatically
3. **Preview** — review all staged transactions; uncheck any you want to skip
4. **Confirm** — transactions are saved; duplicates (same hash) are silently skipped

Hash-based deduplication means you can safely re-upload last month's statement when you also have this month's — only new rows are inserted.

</details>

<details>
<summary><b>🤖 AI Categorisation</b></summary>

<br/>

The categorisation pipeline runs in two stages:

1. **Rule-based** (instant, free) — covers 300+ known Indian merchants: Swiggy, Zomato, Amazon, IRCTC, Paytm, BigBasket, DMart, etc.
2. **AI fallback** (GPT-4o-mini / Gemini) — only for merchants not matched by rules

The AI result is cached in the database per merchant name. "SWIGGY ORDER 982341" hits the cache after the first transaction — every subsequent Swiggy order is categorised instantly, for free.

**Merchant normalisation:** "SWIGGY ORDER 982341" → "Swiggy" · "AMZN MKTPLACE\*PQ82" → "Amazon"

</details>

<details>
<summary><b>📊 Analytics</b></summary>

<br/>

- Monthly income vs. expenses bar chart
- Net cash flow trend line (3, 6, or 12 month range)
- Category breakdown donut chart with legend
- Month-over-month % change for each category
- Savings rate calculation and trend
- **Anomaly detection** — flags categories where current spend is statistically above your historical average, with severity levels (moderate / significant)

</details>

<details>
<summary><b>💬 AI Assistant</b></summary>

<br/>

Ask anything about your finances in plain language:

> *"How much did I spend on food delivery last month?"*  
> *"Am I on track with my grocery budget?"*  
> *"What's my biggest expense category this quarter?"*  
> *"Compare my spending this month vs last month"*

The assistant has read access to your full transaction history. Conversations are persisted — pick up where you left off. Weekly proactive insights are generated automatically and pushed as notifications.

Supports both **OpenAI GPT-4o-mini** and **Google Gemini 1.5** — switch with one env variable.

</details>

---

## 🧪 Tests

```bash
cd backend
pip install -r requirements.txt
pytest tests/ -v
```

**18 tests passing** — auth flows, transaction CRUD, balance integrity, user isolation, analytics calculations. Uses in-memory SQLite — no Docker needed to run tests.

---

## 🔑 Environment Variables

```env
# .env (copy from .env.example)

# Required — generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
JWT_SECRET=your-secret-here
JWT_REFRESH_SECRET=your-other-secret-here

# AI (leave blank to disable AI features — everything else still works)
AI_PROVIDER=openai              # or "gemini"
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...

# Pre-configured in docker-compose.yml — no need to change for local dev
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/finance_db
REDIS_URL=redis://localhost:6379/0
```

Full reference with every variable documented: [`.env.example`](.env.example)

---

## 📡 API Reference

<details>
<summary><b>View all endpoints</b></summary>

<br/>

**Auth**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/auth/register` | Register new user |
| `POST` | `/api/v1/auth/login` | Login → JWT tokens |
| `POST` | `/api/v1/auth/refresh` | Refresh access token |
| `GET` | `/api/v1/auth/me` | Current user profile |

**Transactions**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/transactions` | List (paginated, filterable) |
| `POST` | `/api/v1/transactions` | Create transaction |
| `GET` | `/api/v1/transactions/:id` | Get single transaction |
| `PATCH` | `/api/v1/transactions/:id` | Update transaction |
| `DELETE` | `/api/v1/transactions/:id` | Delete transaction |

**CSV Import**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/imports/upload` | Upload CSV file |
| `GET` | `/api/v1/imports/:id` | Get job status |
| `POST` | `/api/v1/imports/:id/detect-columns` | Auto-detect columns |
| `POST` | `/api/v1/imports/:id/preview` | Preview with mapping |
| `POST` | `/api/v1/imports/:id/confirm` | Confirm and import |

**Analytics**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/analytics/overview` | Income / expense / savings |
| `GET` | `/api/v1/analytics/categories` | Spend by category |
| `GET` | `/api/v1/analytics/cash-flow` | Monthly cash flow |
| `GET` | `/api/v1/analytics/trends` | Month-over-month trends |
| `GET` | `/api/v1/analytics/anomalies` | Anomaly detection |

**Budgets**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/budgets` | List budgets |
| `POST` | `/api/v1/budgets` | Create budget |
| `PUT` | `/api/v1/budgets/:id` | Update budget |
| `DELETE` | `/api/v1/budgets/:id` | Delete budget |

**AI Assistant**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/ai/conversations` | List conversations |
| `POST` | `/api/v1/ai/conversations` | New conversation |
| `POST` | `/api/v1/ai/conversations/:id/messages` | Send message |
| `GET` | `/api/v1/ai/insights` | Proactive insights |

**Notifications**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/notifications` | List notifications |
| `GET` | `/api/v1/notifications/unread-count` | Unread count |
| `POST` | `/api/v1/notifications/:id/read` | Mark as read |
| `POST` | `/api/v1/notifications/mark-all-read` | Mark all read |

Interactive docs (try any endpoint live): **http://localhost:8000/docs**

</details>

---

## 🗂️ Project Structure

```
personal-finance-intelligence/
│
├── 🐍 backend/                    FastAPI async API
│   ├── app/
│   │   ├── api/v1/                Route handlers → delegate to services
│   │   ├── services/              Business logic (import, analytics, budget, auth)
│   │   ├── ai/                    Pluggable AI: OpenAI + Gemini with shared interface
│   │   ├── models/                SQLAlchemy ORM models
│   │   ├── schemas/               Pydantic v2 request/response schemas
│   │   ├── tasks/                 Celery background tasks
│   │   └── core/                  Config, security, logging, exceptions
│   ├── tests/                     18 tests, in-memory SQLite
│   ├── migrations/                Alembic migration scripts
│   └── Dockerfile
│
├── 📱 frontend/                   Flutter mobile app
│   └── lib/
│       ├── features/              Feature-first modules (auth, dashboard, imports…)
│       ├── core/                  Theme, network client, secure storage
│       └── shared/widgets/
│
├── 🌐 web/                        Next.js 16 web dashboard
│   ├── app/
│   │   ├── (auth)/                Login + Register (split-panel layout)
│   │   └── (app)/                 Sidebar shell — all 12 app pages
│   ├── components/
│   │   ├── layout/                Sidebar (animated, layoutId nav), Topbar
│   │   ├── motion/                AnimatedNumber, PageTransition, Stagger
│   │   └── ui/                    Button, Card, Dialog, Input, Progress, Skeleton…
│   ├── contexts/auth.tsx          JWT context + silent refresh
│   ├── lib/
│   │   ├── api/                   Type-safe API client per resource
│   │   ├── motion.ts              Spring presets + shared animation variants
│   │   └── utils.ts               cn(), formatCurrency (INR/lakh), formatDate
│   └── types/index.ts             TypeScript types mirroring backend schemas
│
├── 🐳 docker-compose.yml          Postgres + Redis + API + Celery worker
├── 📄 .env.example                Every variable documented
└── 📖 README.md
```

---

## 🛠️ Tech Decisions

<details>
<summary><b>Why FastAPI over Django?</b></summary>
FastAPI is async-native — the right fit for an I/O-heavy backend that makes concurrent database queries, Redis reads, and AI API calls. Pydantic v2 validates every request automatically. Django's ORM and admin are unnecessary overhead for an API-only service.
</details>

<details>
<summary><b>Why Celery for CSV processing?</b></summary>
Parsing and AI-categorising 1,000+ transactions takes 20–30 seconds. FastAPI BackgroundTasks runs in-process and blocks the event loop. Celery workers are out-of-process, scale independently, and retry on failure — the API returns a job ID immediately and the client polls status.
</details>

<details>
<summary><b>Why PostgreSQL over NoSQL?</b></summary>
Financial data is inherently relational: users → accounts → transactions → categories → budgets. SQL aggregations (GROUP BY, month-over-month, savings rate) are clean and fast with proper indexing. The schema is stable and well-defined — document stores add no benefit here.
</details>

<details>
<summary><b>Why Tailwind v4 CSS-first config?</b></summary>
v4 uses <code>@theme {}</code> directives instead of <code>tailwind.config.js</code> — all design tokens become CSS custom properties (<code>var(--color-accent)</code> etc.). This makes Recharts styling trivial since chart props accept CSS variable strings directly.
</details>

<details>
<summary><b>Why Framer Motion?</b></summary>
Spring physics (<code>stiffness</code>, <code>damping</code>, <code>mass</code>) produce natural-feeling motion without hand-coding CSS transitions. <code>layoutId</code> shared-layout makes the nav indicator slide between items with zero position math. <code>AnimatePresence</code> handles mount/unmount — critical for page transitions and dialogs.
</details>

---

## 📸 Screenshots

> Dashboard · CSV Import · Budget Tracking · AI Chat — *coming soon*

---

<div align="center">

**Built by [Aayush Ramrakhyani](https://github.com/Aayush-Ramrakhyani)**

*This is a personal project. All rights reserved.*

</div>
