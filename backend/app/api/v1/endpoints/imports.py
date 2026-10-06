import os
import uuid
from uuid import UUID

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import FileValidationError
from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.common import SuccessResponse
from app.schemas.import_job import (
    ColumnMappingRequest,
    ConfirmImportRequest,
    DetectedColumns,
    ImportJobResponse,
    ImportPreviewResponse,
)
from app.services.import_service import ImportService

router = APIRouter(prefix="/imports", tags=["imports"])

ALLOWED_EXTENSIONS = {".csv", ".txt"}
MAX_SIZE_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024


@router.post("", response_model=SuccessResponse[ImportJobResponse], status_code=201)
async def upload_csv(
    file: UploadFile = File(...),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Upload a CSV file and create an import job."""
    if not file.filename:
        raise FileValidationError("No file provided.")

    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise FileValidationError(f"Only CSV files are allowed. Got: {ext}")

    content = await file.read()
    if len(content) > MAX_SIZE_BYTES:
        raise FileValidationError(
            f"File too large. Maximum size is {settings.MAX_UPLOAD_SIZE_MB}MB."
        )
    if len(content) == 0:
        raise FileValidationError("File is empty.")

    # Save file
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    safe_name = f"{uuid.uuid4()}_{file.filename.replace(' ', '_')}"
    file_path = os.path.join(settings.UPLOAD_DIR, safe_name)
    with open(file_path, "wb") as f:
        f.write(content)

    svc = ImportService(db)
    job = await svc.create_import_job(user_id, file_path, file.filename)
    return SuccessResponse(data=job)


@router.get("/{job_id}", response_model=SuccessResponse[ImportJobResponse])
async def get_import_job(
    job_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    import sqlalchemy as sa
    from app.models.import_job import ImportJob
    result = await db.execute(
        sa.select(ImportJob).where(
            ImportJob.id == job_id, ImportJob.user_id == user_id
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Import job")
    return SuccessResponse(data=ImportJobResponse.model_validate(job))


@router.get("/{job_id}/columns", response_model=SuccessResponse[DetectedColumns])
async def detect_columns(
    job_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    import sqlalchemy as sa
    from app.models.import_job import ImportJob
    result = await db.execute(
        sa.select(ImportJob).where(
            ImportJob.id == job_id, ImportJob.user_id == user_id
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Import job")

    svc = ImportService(db)
    detected = await svc.detect_columns(job.file_path)
    return SuccessResponse(data=detected)


@router.post("/{job_id}/preview", response_model=SuccessResponse[ImportPreviewResponse])
async def preview_import(
    job_id: UUID,
    mapping: ColumnMappingRequest,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = ImportService(db)
    preview = await svc.preview_import(job_id, mapping, user_id)
    return SuccessResponse(data=preview)


@router.post("/{job_id}/confirm", response_model=SuccessResponse[dict])
async def confirm_import(
    job_id: UUID,
    request: ConfirmImportRequest,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = ImportService(db)
    result = await svc.confirm_import(job_id, user_id, request.exclude_ids)
    return SuccessResponse(data=result)
