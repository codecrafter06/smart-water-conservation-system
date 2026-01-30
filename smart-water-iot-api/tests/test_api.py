"""
API endpoint tests for Smart Water IoT API.
Tests all endpoints for correct behavior.
"""

import json
import pytest


class TestHealthEndpoint:
    """Tests for the health check endpoint."""
    
    def test_health_check_returns_ok(self, client):
        """Health endpoint should return 200 with healthy status."""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "healthy"
        assert "version" in data
        assert "timestamp" in data
    
    def test_api_health_check(self, client):
        """API-prefixed health endpoint should also work."""
        response = client.get("/api/v1/health")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "healthy"


class TestSensorIngestEndpoint:
    """Tests for the sensor data ingestion endpoint."""
    
    def test_ingest_valid_data(self, client, sample_sensor_data):
        """Should successfully ingest valid sensor data."""
        response = client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(sample_sensor_data),
            content_type="application/json"
        )
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["success"] is True
        assert data["device_id"] == sample_sensor_data["device_id"]
        assert "document_id" in data
        assert "analysis" in data
    
    def test_ingest_missing_device_id(self, client):
        """Should return 400 when device_id is missing."""
        invalid_data = {
            "tank_id": "TANK-001",
            "water_level_percent": 50,
            "flow_rate_lpm": 5.0,
        }
        
        response = client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(invalid_data),
            content_type="application/json"
        )
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert "error" in data
        assert "device_id" in data["error"].get("field", "") or "device_id" in data["error"].get("message", "")
    
    def test_ingest_invalid_water_level(self, client):
        """Should return 400 when water level is out of range."""
        invalid_data = {
            "device_id": "SENSOR-001",
            "tank_id": "TANK-001",
            "water_level_percent": 150,  # Invalid: over 100
            "flow_rate_lpm": 5.0,
        }
        
        response = client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(invalid_data),
            content_type="application/json"
        )
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert "error" in data
    
    def test_ingest_overflow_triggers_alert(self, client, overflow_sensor_data):
        """Should detect overflow risk and include alert in response."""
        response = client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(overflow_sensor_data),
            content_type="application/json"
        )
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["analysis"]["status"] == "overflow_risk"
        assert data["analysis"]["alerts_count"] > 0
    
    def test_ingest_low_water_triggers_alert(self, client, low_level_sensor_data):
        """Should detect low water and include alert in response."""
        response = client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(low_level_sensor_data),
            content_type="application/json"
        )
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["analysis"]["alerts_count"] > 0
        
        alert_types = [a["type"] for a in data["analysis"]["alerts"]]
        assert "low_water" in alert_types
    
    def test_ingest_empty_body(self, client):
        """Should return 400 when request body is empty."""
        response = client.post(
            "/api/v1/sensors/ingest",
            data="",
            content_type="application/json"
        )
        
        assert response.status_code == 400


class TestDashboardEndpoint:
    """Tests for the live dashboard endpoint."""
    
    def test_get_live_dashboard(self, client):
        """Should return dashboard data with expected structure."""
        response = client.get("/api/v1/dashboard/live")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        # Check required fields
        assert "timestamp" in data
        assert "status" in data
        assert "tank_status" in data
        assert "alerts" in data
    
    def test_dashboard_tank_status_fields(self, client):
        """Dashboard should include tank status with all required fields."""
        response = client.get("/api/v1/dashboard/live")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        tank_status = data["tank_status"]
        assert "water_level_percent" in tank_status
        assert "flow_rate_lpm" in tank_status
        assert "is_filling" in tank_status
        assert "is_draining" in tank_status


class TestAnalyticsEndpoint:
    """Tests for the analytics endpoints."""
    
    def test_get_daily_analytics(self, client):
        """Should return daily analytics with expected structure."""
        response = client.get("/api/v1/analytics/daily")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        assert "period" in data
        assert "summary" in data
        assert "daily_data" in data
        assert isinstance(data["daily_data"], list)
    
    def test_daily_analytics_with_days_param(self, client):
        """Should respect the days parameter."""
        response = client.get("/api/v1/analytics/daily?days=3")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["period"]["days"] == 3
    
    def test_daily_analytics_clamps_days(self, client):
        """Should clamp days parameter to valid range."""
        response = client.get("/api/v1/analytics/daily?days=100")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["period"]["days"] <= 30
    
    def test_get_weekly_summary(self, client):
        """Should return weekly summary."""
        response = client.get("/api/v1/analytics/weekly")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        assert "week_start" in data
        assert "week_end" in data
        assert "total_consumption_liters" in data
    
    def test_get_hourly_pattern(self, client):
        """Should return hourly usage pattern."""
        response = client.get("/api/v1/analytics/hourly-pattern")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        assert "hourly_pattern" in data
        assert len(data["hourly_pattern"]) == 24  # 24 hours


class TestAlertsEndpoint:
    """Tests for the alerts endpoint."""
    
    def test_get_alerts(self, client):
        """Should return alerts list."""
        response = client.get("/api/v1/alerts")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        assert "count" in data
        assert "alerts" in data
        assert isinstance(data["alerts"], list)
    
    def test_alerts_with_limit(self, client):
        """Should respect limit parameter."""
        response = client.get("/api/v1/alerts?limit=5")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data["alerts"]) <= 5
    
    def test_active_alerts_filter(self, client, overflow_sensor_data):
        """Should filter for active alerts only when requested."""
        # First, generate an alert
        client.post(
            "/api/v1/sensors/ingest",
            data=json.dumps(overflow_sensor_data),
            content_type="application/json"
        )
        
        # Get active alerts
        response = client.get("/api/v1/alerts?active_only=true")
        
        assert response.status_code == 200
        data = json.loads(response.data)
        
        # All returned alerts should be unacknowledged
        for alert in data["alerts"]:
            assert alert.get("acknowledged", False) is False


class TestErrorHandling:
    """Tests for error handling."""
    
    def test_404_not_found(self, client):
        """Should return proper 404 error for unknown routes."""
        response = client.get("/api/v1/unknown-endpoint")
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert "error" in data
    
    def test_method_not_allowed(self, client):
        """Should handle method not allowed appropriately."""
        response = client.post("/api/v1/dashboard/live")
        
        assert response.status_code == 405
    
    def test_invalid_json(self, client):
        """Should return 400 for invalid JSON."""
        response = client.post(
            "/api/v1/sensors/ingest",
            data="not valid json",
            content_type="application/json"
        )
        
        assert response.status_code == 400
