"""
Test configuration and fixtures for pytest.
"""

import pytest
from src.smart_water_api.app_factory import create_app
from src.smart_water_api.services.sensor_service import reset_mock_db


@pytest.fixture
def app():
    """Create application for testing."""
    app = create_app({
        "TESTING": True,
        "USE_MOCK_FIREBASE": True,
    })
    
    yield app
    
    # Cleanup: reset mock database after each test
    reset_mock_db()


@pytest.fixture
def client(app):
    """Create test client."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create test CLI runner."""
    return app.test_cli_runner()


@pytest.fixture
def sample_sensor_data():
    """Provide sample sensor data for tests."""
    return {
        "device_id": "TEST-SENSOR-001",
        "tank_id": "TEST-TANK-001",
        "water_level_percent": 65.5,
        "flow_rate_lpm": 5.2,
        "timestamp": "2024-01-15T10:30:00Z",
    }


@pytest.fixture
def overflow_sensor_data():
    """Provide sensor data that should trigger overflow alert."""
    return {
        "device_id": "TEST-SENSOR-001",
        "tank_id": "TEST-TANK-001",
        "water_level_percent": 96.0,
        "flow_rate_lpm": 8.5,
        "timestamp": "2024-01-15T10:30:00Z",
    }


@pytest.fixture
def low_level_sensor_data():
    """Provide sensor data that should trigger low water alert."""
    return {
        "device_id": "TEST-SENSOR-001",
        "tank_id": "TEST-TANK-001",
        "water_level_percent": 8.0,
        "flow_rate_lpm": 1.0,
        "timestamp": "2024-01-15T10:30:00Z",
    }
