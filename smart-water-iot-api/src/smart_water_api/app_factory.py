"""
Application Factory - Creates and configures the Flask application.
Uses factory pattern for flexibility and testing.
"""

import logging
from flask import Flask

from .config import get_config
from .extensions import cors
from .errors.handlers import register_error_handlers
from .api.routes import api_bp, register_health_route


def create_app(config_override: dict = None) -> Flask:
    """
    Create and configure the Flask application.
    
    Args:
        config_override: Optional dictionary of config values to override
        
    Returns:
        Configured Flask application instance
    """
    app = Flask(__name__)
    
    # Load configuration
    config = get_config()
    app.config.from_object(config)
    
    # Apply any overrides
    if config_override:
        app.config.update(config_override)
    
    # Configure logging
    _configure_logging(app)
    
    # Initialize extensions
    _init_extensions(app)
    
    # Register blueprints
    _register_blueprints(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register root-level health check
    register_health_route(app)
    
    app.logger.info(f"Smart Water API initialized in {app.config.get('ENV', 'development')} mode")
    
    return app


def _configure_logging(app: Flask) -> None:
    """Configure application logging."""
    log_level = app.config.get("LOG_LEVEL", "INFO")
    
    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    
    # Set Flask's logger
    app.logger.setLevel(getattr(logging, log_level, logging.INFO))


def _init_extensions(app: Flask) -> None:
    """Initialize Flask extensions."""
    # Initialize CORS with permissive settings for development
    cors.init_app(
        app,
        origins="*",
        allow_headers=["Content-Type", "Authorization"],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        supports_credentials=True
    )


def _register_blueprints(app: Flask) -> None:
    """Register application blueprints."""
    app.register_blueprint(api_bp)
