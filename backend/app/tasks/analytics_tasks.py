from app.tasks.celery_app import celery_app
from app.core.logging import get_logger

logger = get_logger(__name__)


@celery_app.task(name="detect_recurring_all_users")
def detect_recurring_all_users():
    """Periodic task: detect recurring transactions for all active users."""
    import asyncio

    async def _run():
        import sqlalchemy as sa
        from app.db.base import AsyncSessionLocal
        from app.models.user import User
        from app.services.recurring_service import RecurringService

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                sa.select(User.id).where(User.is_active == True)
            )
            user_ids = result.scalars().all()
            svc = RecurringService(db)
            for uid in user_ids:
                try:
                    await svc.detect_and_update(uid)
                    await db.commit()
                except Exception as e:
                    logger.error("recurring_detection_failed", user_id=str(uid), error=str(e))

    asyncio.run(_run())


@celery_app.task(name="generate_monthly_insights")
def generate_monthly_insights(month: int, year: int):
    """Generate insights for all users for a given month."""
    import asyncio

    async def _run():
        import sqlalchemy as sa
        from app.db.base import AsyncSessionLocal
        from app.models.user import User
        from app.ai.factory import get_ai_provider
        from app.ai.insight_service import InsightService

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                sa.select(User.id).where(User.is_active == True)
            )
            user_ids = result.scalars().all()
            try:
                provider = get_ai_provider()
            except Exception:
                provider = None

            for uid in user_ids:
                try:
                    svc = InsightService(db, provider)
                    await svc.generate_monthly_insights(uid, month, year)
                    await db.commit()
                except Exception as e:
                    logger.error("insight_generation_failed", user_id=str(uid), error=str(e))

    asyncio.run(_run())
