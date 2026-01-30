"""
Custom exception classes for the Smart Water API.
All exceptions inherit from APIError for consistent handling.
"""

from ..constants import HTTP_BAD_REQUEST, HTTP_NOT_FOUND, HTTP_INTERNAL_ERROR


class APIError(Exception):
    """Base exception for all API errors."""
    
    def __init__(
        self,
        message: str,
        status_code: int = HTTP_INTERNAL_ERROR,
        error_code: str = "INTERNAL_ERROR"
    ):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
    
    def to_dict(self) -> dict:
        """Convert exception to dictionary for JSON response."""
        return {
            "error": {
                "code": self.error_code,
                "message": self.message,
            }
        }


class ValidationError(APIError):
    """Raised when input validation fails."""
    
    def __init__(self, message: str, field: str = None):
        super().__init__(
            message=message,
            status_code=HTTP_BAD_REQUEST,
            error_code="VALIDATION_ERROR"
        )
        self.field = field
    
    def to_dict(self) -> dict:
        """Include field information in error response."""
        result = super().to_dict()
        if self.field:
            result["error"]["field"] = self.field
        return result


class NotFoundError(APIError):
    """Raised when a requested resource is not found."""
    
    def __init__(self, message: str = "Resource not found"):
        super().__init__(
            message=message,
            status_code=HTTP_NOT_FOUND,
            error_code="NOT_FOUND"
        )


class SensorDataError(APIError):
    """Raised when sensor data processing fails."""
    
    def __init__(self, message: str, device_id: str = None):
        super().__init__(
            message=message,
            status_code=HTTP_BAD_REQUEST,
            error_code="SENSOR_DATA_ERROR"
        )
        self.device_id = device_id
    
    def to_dict(self) -> dict:
        """Include device information in error response."""
        result = super().to_dict()
        if self.device_id:
            result["error"]["device_id"] = self.device_id
        return result


class FirebaseError(APIError):
    """Raised when Firebase operations fail."""
    
    def __init__(self, message: str = "Database operation failed"):
        super().__init__(
            message=message,
            status_code=HTTP_INTERNAL_ERROR,
            error_code="DATABASE_ERROR"
        )
