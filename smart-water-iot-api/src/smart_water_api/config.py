"""
Configuration module for Flask application.
Handles environment-specific settings.
"""

import os
from typing import Optional


class BaseConfig:
    """Base configuration with default values."""
    
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")
    DEBUG: bool = False
    TESTING: bool = False
    
    # Firebase Configuration
    FIREBASE_PROJECT_ID: Optional[str] = os.getenv("FIREBASE_PROJECT_ID")
    FIREBASE_CREDENTIALS_PATH: Optional[str] = os.getenv("FIREBASE_CREDENTIALS_PATH")
    
    # CORS Settings
    CORS_ORIGINS: list = ["*"]  # Restrict in production
    
    # API Settings
    JSON_SORT_KEYS: bool = False
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


class DevelopmentConfig(BaseConfig):
    """Development environment configuration."""
    
    DEBUG: bool = True
    LOG_LEVEL: str = "DEBUG"
    
    # Use mock Firebase in development
    USE_MOCK_FIREBASE: bool = True


class TestingConfig(BaseConfig):
    """Testing environment configuration."""
    
    TESTING: bool = True
    DEBUG: bool = True
    
    # Always use mock Firebase in tests
    USE_MOCK_FIREBASE: bool = True


class ProductionConfig(BaseConfig):
    """Production environment configuration."""
    
    DEBUG: bool = False
    
    # Production should use real Firebase
    USE_MOCK_FIREBASE: bool = False
    
    # Restrict CORS in production
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "").split(",")


def get_config() -> BaseConfig:
    """Get configuration based on environment."""
    env = os.getenv("FLASK_ENV", "development").lower()
    
    config_map = {
        "development": DevelopmentConfig,
        "testing": TestingConfig,
        "production": ProductionConfig,
    }
    
    return config_map.get(env, DevelopmentConfig)()
