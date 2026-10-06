from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.auth import LoginRequest, RefreshRequest, RegisterRequest, TokenResponse, UserResponse
from app.schemas.common import SuccessResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=SuccessResponse[dict])
async def register(
    request: RegisterRequest, db: AsyncSession = Depends(get_db)
):
    """Register a new user."""
    service = AuthService(db)
    user, tokens = await service.register(request)
    return SuccessResponse(data={"user": user.model_dump(mode="json"), **tokens.model_dump()})


@router.post("/login", response_model=SuccessResponse[dict])
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login with email and password."""
    service = AuthService(db)
    user, tokens = await service.login(request)
    return SuccessResponse(data={"user": user.model_dump(mode="json"), **tokens.model_dump()})


@router.post("/refresh", response_model=SuccessResponse[TokenResponse])
async def refresh_token(request: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token."""
    service = AuthService(db)
    tokens = await service.refresh_token(request.refresh_token)
    return SuccessResponse(data=tokens)


@router.get("/me", response_model=SuccessResponse[UserResponse])
async def get_me(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Get current authenticated user."""
    service = AuthService(db)
    user = await service.get_current_user(user_id)
    return SuccessResponse(data=user)
