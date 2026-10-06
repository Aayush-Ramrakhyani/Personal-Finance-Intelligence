from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AuthenticationError, DuplicateError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    hash_password,
    verify_password,
)
from app.db.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse


class AuthService:
    def __init__(self, db: AsyncSession):
        self.user_repo = UserRepository(db)

    async def register(self, request: RegisterRequest) -> tuple[UserResponse, TokenResponse]:
        existing = await self.user_repo.get_by_email(request.email)
        if existing:
            raise DuplicateError("Email")

        password_hash = hash_password(request.password)
        user = await self.user_repo.create_user(
            email=request.email,
            password_hash=password_hash,
            first_name=request.first_name,
            last_name=request.last_name,
            currency=request.currency,
            timezone=request.timezone,
        )

        tokens = self._create_tokens(user.id)
        return UserResponse.model_validate(user), tokens

    async def login(self, request: LoginRequest) -> tuple[UserResponse, TokenResponse]:
        user = await self.user_repo.get_by_email(request.email)
        if not user or not verify_password(request.password, user.password_hash):
            raise AuthenticationError("Invalid email or password.")
        if not user.is_active:
            raise AuthenticationError("Account is deactivated.")

        tokens = self._create_tokens(user.id)
        return UserResponse.model_validate(user), tokens

    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        payload = decode_refresh_token(refresh_token)
        user_id = UUID(payload["sub"])
        user = await self.user_repo.get(user_id)
        if not user or not user.is_active:
            raise AuthenticationError("Invalid refresh token.")
        return self._create_tokens(user_id)

    async def get_current_user(self, user_id: UUID) -> UserResponse:
        user = await self.user_repo.get(user_id)
        if not user:
            raise AuthenticationError("User not found.")
        return UserResponse.model_validate(user)

    def _create_tokens(self, user_id: UUID) -> TokenResponse:
        access_token = create_access_token({"sub": str(user_id)})
        refresh_token = create_refresh_token({"sub": str(user_id)})
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
