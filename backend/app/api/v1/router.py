from fastapi import APIRouter

from app.api.v1.endpoints import (
    accounts,
    ai,
    analytics,
    auth,
    budgets,
    categories,
    health,
    imports,
    notifications,
    recurring,
    reports,
    transactions,
)

api_router = APIRouter()

api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(accounts.router)
api_router.include_router(transactions.router)
api_router.include_router(categories.router)
api_router.include_router(budgets.router)
api_router.include_router(imports.router)
api_router.include_router(analytics.router)
api_router.include_router(recurring.router)
api_router.include_router(notifications.router)
api_router.include_router(ai.router)
api_router.include_router(reports.router)
