"""Error handling module."""

from .exceptions import (
    APIError,
    ValidationError,
    NotFoundError,
    SensorDataError,
    FirebaseError,
)
from .handlers import register_error_handlers

__all__ = [
    "APIError",
    "ValidationError", 
    "NotFoundError",
    "SensorDataError",
    "FirebaseError",
    "register_error_handlers",
]
