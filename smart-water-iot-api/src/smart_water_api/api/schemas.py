"""
Request/Response schemas for API validation.
Defines the expected structure of API requests and responses.
"""

from typing import TypedDict, Optional, List


class SensorIngestRequest(TypedDict):
    """Schema for sensor data ingestion request."""
    device_id: str
    tank_id: str
    water_level_percent: float
    flow_rate_lpm: float
    timestamp: Optional[str]


class SensorIngestResponse(TypedDict):
    """Schema for sensor data ingestion response."""
    success: bool
    document_id: str
    device_id: str
    tank_id: str
    timestamp: str
    analysis: dict


class DashboardResponse(TypedDict):
    """Schema for live dashboard response."""
    timestamp: str
    latest_reading: dict
    status: str
    status_message: str
    alerts: List[dict]
    tank_status: dict


class AnalyticsResponse(TypedDict):
    """Schema for analytics response."""
    period: dict
    summary: dict
    daily_data: List[dict]


class HealthResponse(TypedDict):
    """Schema for health check response."""
    status: str
    version: str
    timestamp: str


class ErrorResponse(TypedDict):
    """Schema for error responses."""
    error: dict
