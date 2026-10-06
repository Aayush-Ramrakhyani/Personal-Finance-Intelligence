import uuid
from datetime import datetime, timezone
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class ImportJob(Base):
    __tablename__ = "import_jobs"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    filename: Mapped[str] = mapped_column(sa.String(255), nullable=False)
    file_path: Mapped[str] = mapped_column(sa.String(500), nullable=False)
    status: Mapped[str] = mapped_column(
        sa.String(30), nullable=False, default="pending"
    )  # pending, processing, preview_ready, confirmed, completed, failed
    column_mapping: Mapped[Optional[dict]] = mapped_column(sa.JSON, nullable=True)
    total_rows: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    processed_rows: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    imported_rows: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    duplicate_rows: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    failed_rows: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    error_message: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        sa.DateTime(timezone=True), nullable=True
    )

    # Relationships
    user: Mapped["User"] = relationship("User")
    staged_transactions: Mapped[list["ImportTransaction"]] = relationship(
        "ImportTransaction", back_populates="import_job", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<ImportJob {self.filename} ({self.status})>"
