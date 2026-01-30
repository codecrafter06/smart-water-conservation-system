"""
Error handlers for Flask application.
Provides consistent JSON error responses for all exceptions.
"""

import logging
from flask import Flask, jsonify
from .exceptions import APIError
from ..constants import HTTP_INTERNAL_ERROR, HTTP_NOT_FOUND, HTTP_BAD_REQUEST

logger = logging.getLogger(__name__)


def register_error_handlers(app: Flask) -> None:
    """Register all error handlers with the Flask application."""
    
    @app.errorhandler(APIError)
    def handle_api_error(error: APIError):
        """Handle custom API errors."""
        logger.warning(f"API Error: {error.error_code} - {error.message}")
        response = jsonify(error.to_dict())
        response.status_code = error.status_code
        return response
    
    @app.errorhandler(HTTP_BAD_REQUEST)
    def handle_bad_request(error):
        """Handle 400 Bad Request errors."""
        return jsonify({
            "error": {
                "code": "BAD_REQUEST",
                "message": "Invalid request format or parameters"
            }
        }), HTTP_BAD_REQUEST
    
    @app.errorhandler(HTTP_NOT_FOUND)
    def handle_not_found(error):
        """Handle 404 Not Found errors."""
        return jsonify({
            "error": {
                "code": "NOT_FOUND",
                "message": "The requested resource was not found"
            }
        }), HTTP_NOT_FOUND
    
    @app.errorhandler(HTTP_INTERNAL_ERROR)
    def handle_internal_error(error):
        """Handle 500 Internal Server errors."""
        logger.error(f"Internal Server Error: {str(error)}")
        return jsonify({
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred"
            }
        }), HTTP_INTERNAL_ERROR
    
    @app.errorhandler(Exception)
    def handle_unexpected_error(error):
        """Catch-all handler for unexpected exceptions."""
        logger.exception(f"Unexpected error: {str(error)}")
        return jsonify({
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred"
            }
        }), HTTP_INTERNAL_ERROR
