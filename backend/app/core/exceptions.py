from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse


class FinanceException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class NotFoundError(FinanceException):
    def __init__(self, resource: str = "Resource"):
        super().__init__(
            code=f"{resource.upper().replace(' ', '_')}_NOT_FOUND",
            message=f"{resource} not found.",
            status_code=404,
        )


class AuthenticationError(FinanceException):
    def __init__(self, message: str = "Authentication failed."):
        super().__init__(code="AUTHENTICATION_FAILED", message=message, status_code=401)


class AuthorizationError(FinanceException):
    def __init__(self, message: str = "Access denied."):
        super().__init__(code="ACCESS_DENIED", message=message, status_code=403)


class DuplicateError(FinanceException):
    def __init__(self, resource: str = "Resource"):
        super().__init__(
            code=f"{resource.upper().replace(' ', '_')}_ALREADY_EXISTS",
            message=f"{resource} already exists.",
            status_code=409,
        )


class BusinessLogicError(FinanceException):
    def __init__(self, message: str, code: str = "BUSINESS_LOGIC_ERROR"):
        super().__init__(code=code, message=message, status_code=400)


class AIProviderError(FinanceException):
    def __init__(self, message: str = "AI provider is not configured or unavailable."):
        super().__init__(code="AI_PROVIDER_ERROR", message=message, status_code=503)


class ImportProcessingError(FinanceException):
    def __init__(self, message: str):
        super().__init__(code="IMPORT_PROCESSING_ERROR", message=message, status_code=400)


class FileValidationError(FinanceException):
    def __init__(self, message: str):
        super().__init__(code="FILE_VALIDATION_ERROR", message=message, status_code=400)


def _error_response(code: str, message: str, status_code: int) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"success": False, "error": {"code": code, "message": message}},
    )


async def finance_exception_handler(request: Request, exc: FinanceException) -> JSONResponse:
    return _error_response(exc.code, exc.message, exc.status_code)


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    return _error_response("HTTP_ERROR", exc.detail or "An error occurred.", exc.status_code)


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return _error_response(
        "INTERNAL_SERVER_ERROR",
        "An unexpected error occurred. Please try again.",
        500,
    )
