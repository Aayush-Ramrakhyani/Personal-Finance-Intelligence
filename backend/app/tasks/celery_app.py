"""
celery_app.py
Celery application factory for the finance background worker; configures Redis broker,
JSON serialization, IST timezone, and late-ack mode for reliable task processing.
"""
from celery import Celery
from app.core.config import settings

celery_app = Celery(
    "finance_worker",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.tasks.import_tasks", "app.tasks.analytics_tasks"],  # auto-discover task modules
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Kolkata",
    enable_utc=True,
    task_track_started=True,
    worker_prefetch_multiplier=1,  # one task at a time per worker for fair queue processing
    task_acks_late=True,  # acknowledge only after task succeeds, preventing message loss on crash
)
