from app.tasks.celery_app import celery_app
from app.core.logging import get_logger

logger = get_logger(__name__)


@celery_app.task(name="process_import", bind=True, max_retries=3)
def process_import(self, job_id: str, user_id: str):
    """Background task to process a large CSV import."""
    import asyncio
    from uuid import UUID

    async def _run():
        from app.db.base import AsyncSessionLocal
        from app.services.import_service import ImportService
        async with AsyncSessionLocal() as db:
            logger.info("import_task_started", job_id=job_id)

    try:
        asyncio.run(_run())
    except Exception as exc:
        logger.error("import_task_failed", job_id=job_id, error=str(exc))
        raise self.retry(exc=exc, countdown=60)
