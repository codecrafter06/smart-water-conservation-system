"""
API Routes - All REST endpoints for the Smart Water API.
Organized using Flask Blueprint for modularity.
"""

import logging
from datetime import datetime
from flask import Blueprint, request, jsonify

from ..constants import API_PREFIX, HTTP_OK, HTTP_CREATED, STATUS_NORMAL
from ..services.sensor_service import SensorService
from ..services.analytics_service import AnalyticsService
from ..services.alert_service import AlertService
from ..utils.validators import validate_sensor_data
from ..errors.exceptions import ValidationError
from .. import __version__

logger = logging.getLogger(__name__)

# Create Blueprint with API prefix
api_bp = Blueprint("api", __name__, url_prefix=API_PREFIX)

# Service instances (singleton pattern for simplicity)
_sensor_service = None
_analytics_service = None
_alert_service = None


def get_sensor_service() -> SensorService:
    """Get or create sensor service instance."""
    global _sensor_service
    if _sensor_service is None:
        _sensor_service = SensorService(use_mock=True)
    return _sensor_service


def get_analytics_service() -> AnalyticsService:
    """Get or create analytics service instance."""
    global _analytics_service
    if _analytics_service is None:
        _analytics_service = AnalyticsService(get_sensor_service())
    return _analytics_service


def get_alert_service() -> AlertService:
    """Get or create alert service instance."""
    global _alert_service
    if _alert_service is None:
        _alert_service = AlertService()
    return _alert_service


# ============================================================================
# Health Check Endpoint
# ============================================================================

@api_bp.route("/health", methods=["GET"])
def health_check():
    """
    Health check endpoint.
    
    Returns:
        JSON with health status, version, and timestamp
    """
    return jsonify({
        "status": "healthy",
        "version": __version__,
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    }), HTTP_OK


# Also register at root level for convenience
def register_health_route(app):
    """Register health route at application root."""
    @app.route("/health", methods=["GET"])
    def root_health():
        return jsonify({
            "status": "healthy",
            "version": __version__,
            "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        }), HTTP_OK


# ============================================================================
# Sensor Data Endpoints
# ============================================================================

@api_bp.route("/sensors/ingest", methods=["POST"])
def ingest_sensor_data():
    """
    Ingest sensor reading data.
    
    Accepts JSON body with:
        - device_id: Unique identifier for the sensor device
        - tank_id: Identifier for the water tank
        - water_level_percent: Current water level (0-100)
        - flow_rate_lpm: Flow rate in liters per minute
        - timestamp: Optional ISO timestamp
    
    Returns:
        JSON with ingestion result and any detected alerts
    """
    # Get JSON data from request
    data = request.get_json()
    
    if not data:
        raise ValidationError("Request body must be valid JSON")
    
    # Validate input data
    validated_data = validate_sensor_data(data)
    
    # Ingest the reading
    sensor_service = get_sensor_service()
    result = sensor_service.ingest_reading(validated_data)
    
    # Analyze for alerts
    alert_service = get_alert_service()
    analysis = alert_service.analyze_reading(validated_data)
    
    response = {
        **result,
        "analysis": {
            "status": analysis["status"],
            "status_message": analysis["status_message"],
            "alerts_count": analysis["alerts_count"],
            "alerts": analysis["alerts"],
        }
    }
    
    logger.info(f"Ingested sensor data from {validated_data['device_id']}")
    
    return jsonify(response), HTTP_CREATED


# ============================================================================
# Dashboard Endpoints
# ============================================================================

@api_bp.route("/dashboard/live", methods=["GET"])
def get_live_dashboard():
    """
    Get live dashboard data.
    
    Returns current sensor readings, status, and active alerts
    suitable for real-time dashboard display.
    
    Returns:
        JSON with latest reading, status, and alerts
    """
    sensor_service = get_sensor_service()
    alert_service = get_alert_service()
    
    # Get latest readings
    latest_readings = sensor_service.get_latest_readings(limit=1)
    
    if not latest_readings:
        # Return default state if no readings
        return jsonify({
            "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "latest_reading": None,
            "status": STATUS_NORMAL,
            "status_message": "No sensor data available",
            "alerts": [],
            "tank_status": {
                "water_level_percent": 0,
                "flow_rate_lpm": 0,
                "is_filling": False,
                "is_draining": False,
            },
        }), HTTP_OK
    
    latest = latest_readings[0]
    
    # Analyze the latest reading
    analysis = alert_service.analyze_reading(latest)
    
    # Get active alerts
    active_alerts = alert_service.get_active_alerts()
    
    # Determine tank status
    water_level = latest.get("water_level_percent", 0)
    flow_rate = latest.get("flow_rate_lpm", 0)
    
    response = {
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "latest_reading": latest,
        "status": analysis["status"],
        "status_message": analysis["status_message"],
        "alerts": active_alerts[:5],  # Limit to 5 most recent
        "alerts_count": len(active_alerts),
        "tank_status": {
            "water_level_percent": water_level,
            "flow_rate_lpm": flow_rate,
            "is_filling": flow_rate > 5 and water_level < 90,
            "is_draining": flow_rate > 5 and water_level > 10,
            "level_status": _get_level_status(water_level),
        },
    }
    
    return jsonify(response), HTTP_OK


def _get_level_status(water_level: float) -> str:
    """Get human-readable water level status."""
    if water_level >= 90:
        return "Full"
    elif water_level >= 70:
        return "High"
    elif water_level >= 40:
        return "Normal"
    elif water_level >= 20:
        return "Low"
    else:
        return "Critical"


# ============================================================================
# Analytics Endpoints
# ============================================================================

@api_bp.route("/analytics/daily", methods=["GET"])
def get_daily_analytics():
    """
    Get daily water usage analytics.
    
    Query Parameters:
        - days: Number of days to include (default: 7, max: 30)
    
    Returns:
        JSON with daily aggregated water usage data for charts
    """
    # Get days parameter with validation
    days_param = request.args.get("days", "7")
    
    try:
        days = int(days_param)
        days = max(1, min(30, days))  # Clamp between 1 and 30
    except ValueError:
        days = 7
    
    analytics_service = get_analytics_service()
    analytics = analytics_service.get_daily_analytics(days=days)
    
    return jsonify(analytics), HTTP_OK


@api_bp.route("/analytics/weekly", methods=["GET"])
def get_weekly_summary():
    """
    Get weekly usage summary.
    
    Returns:
        JSON with weekly aggregated statistics
    """
    analytics_service = get_analytics_service()
    summary = analytics_service.get_weekly_summary()
    
    return jsonify(summary), HTTP_OK


@api_bp.route("/analytics/hourly-pattern", methods=["GET"])
def get_hourly_pattern():
    """
    Get hourly water usage patterns.
    
    Returns:
        JSON with average hourly usage patterns
    """
    analytics_service = get_analytics_service()
    pattern = analytics_service.get_hourly_pattern()
    
    return jsonify(pattern), HTTP_OK


# ============================================================================
# Alerts Endpoints
# ============================================================================

@api_bp.route("/alerts", methods=["GET"])
def get_alerts():
    """
    Get all alerts.
    
    Query Parameters:
        - limit: Maximum number of alerts to return (default: 50)
        - active_only: If 'true', return only unacknowledged alerts
    
    Returns:
        JSON list of alerts
    """
    limit_param = request.args.get("limit", "50")
    active_only = request.args.get("active_only", "false").lower() == "true"
    
    try:
        limit = int(limit_param)
        limit = max(1, min(100, limit))
    except ValueError:
        limit = 50
    
    alert_service = get_alert_service()
    
    if active_only:
        alerts = alert_service.get_active_alerts()[:limit]
    else:
        alerts = alert_service.get_all_alerts(limit=limit)
    
    return jsonify({
        "count": len(alerts),
        "alerts": alerts,
    }), HTTP_OK


# ============================================================================
# Prediction Endpoints
# ============================================================================

@api_bp.route("/predictions/water-shortage", methods=["GET"])
def predict_water_shortage():
    """
    Predict water shortage based on current usage patterns.
    
    Returns:
        JSON with prediction data including hours remaining and usage comparison
    """
    sensor_service = get_sensor_service()
    analytics_service = get_analytics_service()
    
    # Get current water level
    latest = sensor_service.get_latest_readings(limit=1)
    if not latest:
        return jsonify({
            "error": "No sensor data available",
            "hours_remaining": 0,
            "usage_status": "unknown"
        }), HTTP_OK
    
    current_level = latest[0].get("water_level_percent", 50)
    current_flow = latest[0].get("flow_rate_lpm", 0)
    
    # Get historical average usage (last 7 days)
    analytics = analytics_service.get_daily_analytics(days=7)
    avg_daily_flow = analytics["summary"]["total_water_flow_liters"] / 7
    
    # Get today's usage
    today_analytics = analytics_service.get_daily_analytics(days=1)
    today_flow = today_analytics["summary"]["total_water_flow_liters"]
    
    # Simple prediction logic
    # Assume tank capacity is 1000L (10L per 1%)
    tank_capacity_liters = 1000
    current_water_liters = (current_level / 100) * tank_capacity_liters
    
    # Calculate hours remaining based on current flow rate
    if current_flow > 0:
        hours_remaining = current_water_liters / (current_flow * 60)  # Convert L/min to L/hour
    else:
        # Use average daily consumption
        avg_hourly_consumption = avg_daily_flow / 24
        if avg_hourly_consumption > 0:
            hours_remaining = current_water_liters / avg_hourly_consumption
        else:
            hours_remaining = 999  # Essentially infinite
    
    # Compare today's usage with average
    usage_diff_percent = 0
    if avg_daily_flow > 0:
        usage_diff_percent = ((today_flow - avg_daily_flow) / avg_daily_flow) * 100
    
    # Determine usage status
    if usage_diff_percent > 20:
        usage_status = "high"
        usage_message = f"Today's usage is {abs(usage_diff_percent):.1f}% above normal"
    elif usage_diff_percent < -20:
        usage_status = "low"
        usage_message = f"Today's usage is {abs(usage_diff_percent):.1f}% below normal"
    else:
        usage_status = "normal"
        usage_message = "Today's usage is within normal range"
    
    # Determine warning level
    if hours_remaining < 6:
        warning_level = "critical"
    elif hours_remaining < 12:
        warning_level = "warning"
    elif hours_remaining < 24:
        warning_level = "caution"
    else:
        warning_level = "normal"
    
    return jsonify({
        "hours_remaining": round(hours_remaining, 1),
        "current_level_percent": round(current_level, 1),
        "current_water_liters": round(current_water_liters, 1),
        "usage_status": usage_status,
        "usage_message": usage_message,
        "usage_diff_percent": round(usage_diff_percent, 1),
        "warning_level": warning_level,
        "avg_daily_consumption": round(avg_daily_flow, 1),
        "today_consumption": round(today_flow, 1),
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    }), HTTP_OK


# ============================================================================
# Control Endpoints (Simulation)
# ============================================================================

# Global state for simulation
_control_state = {
    "pump_main": False,
    "valve_inlet": False,
    "valve_outlet": True,
    "auto_mode": True,
}

@api_bp.route("/controls/state", methods=["GET"])
def get_control_state():
    """
    Get current state of all controls.
    
    Returns:
        JSON with current state of pumps and valves
    """
    return jsonify({
        "controls": _control_state,
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    }), HTTP_OK

@api_bp.route("/controls/pump/<pump_id>", methods=["POST"])
def control_pump(pump_id: str):
    """
    Control pump state (ON/OFF).
    
    Body:
        {"state": true/false}
    
    Returns:
        JSON with updated pump state
    """
    data = request.get_json()
    if not data or "state" not in data:
        raise ValidationError("Request must include 'state' field")
    
    state = bool(data["state"])
    control_key = f"pump_{pump_id}"
    
    if control_key in _control_state:
        _control_state[control_key] = state
        logger.info(f"Pump {pump_id} set to {'ON' if state else 'OFF'}")
        
        return jsonify({
            "success": True,
            "pump_id": pump_id,
            "state": state,
            "message": f"Pump {pump_id} turned {'ON' if state else 'OFF'}",
            "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        }), HTTP_OK
    else:
        raise ValidationError(f"Unknown pump: {pump_id}")

@api_bp.route("/controls/valve/<valve_id>", methods=["POST"])
def control_valve(valve_id: str):
    """
    Control valve state (OPEN/CLOSE).
    
    Body:
        {"state": true/false}
    
    Returns:
        JSON with updated valve state
    """
    data = request.get_json()
    if not data or "state" not in data:
        raise ValidationError("Request must include 'state' field")
    
    state = bool(data["state"])
    control_key = f"valve_{valve_id}"
    
    if control_key in _control_state:
        _control_state[control_key] = state
        logger.info(f"Valve {valve_id} set to {'OPEN' if state else 'CLOSED'}")
        
        return jsonify({
            "success": True,
            "valve_id": valve_id,
            "state": state,
            "message": f"Valve {valve_id} {'OPENED' if state else 'CLOSED'}",
            "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        }), HTTP_OK
    else:
        raise ValidationError(f"Unknown valve: {valve_id}")

@api_bp.route("/controls/auto-mode", methods=["POST"])
def control_auto_mode():
    """
    Toggle auto mode.
    
    Body:
        {"state": true/false}
    
    Returns:
        JSON with updated auto mode state
    """
    data = request.get_json()
    if not data or "state" not in data:
        raise ValidationError("Request must include 'state' field")
    
    state = bool(data["state"])
    _control_state["auto_mode"] = state
    logger.info(f"Auto mode set to {'ON' if state else 'OFF'}")
    
    return jsonify({
        "success": True,
        "auto_mode": state,
        "message": f"Auto mode {'enabled' if state else 'disabled'}",
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    }), HTTP_OK


# ============================================================================
# Conservation Report Endpoints
# ============================================================================

@api_bp.route("/reports/conservation", methods=["GET"])
def get_conservation_report():
    """
    Get water conservation report.
    
    Query Parameters:
        - period: 'daily' or 'weekly' (default: 'weekly')
    
    Returns:
        JSON with conservation metrics and explanations
    """
    period = request.args.get("period", "weekly")
    
    analytics_service = get_analytics_service()
    
    # Get analytics for the period
    days = 7 if period == "weekly" else 1
    analytics = analytics_service.get_daily_analytics(days=days)
    
    # Calculate conservation metrics
    total_usage = analytics["summary"]["total_water_flow_liters"]
    avg_daily = total_usage / days
    
    # Baseline: assume 15% higher usage without conservation
    baseline_usage = total_usage * 1.15
    water_saved = baseline_usage - total_usage
    savings_percent = (water_saved / baseline_usage) * 100
    
    # Calculate efficiency based on water level stability
    avg_level = analytics["summary"]["average_daily_level"]
    if avg_level >= 60:
        efficiency = 85 + (avg_level - 60) / 4  # 85-95%
    elif avg_level >= 40:
        efficiency = 70 + (avg_level - 40) / 2  # 70-85%
    else:
        efficiency = 50 + avg_level / 2  # 50-70%
    
    efficiency = min(95, max(50, efficiency))
    
    # Generate insights
    insights = []
    
    if efficiency >= 80:
        insights.append("Excellent water management! System is operating efficiently.")
    elif efficiency >= 70:
        insights.append("Good water usage patterns. Minor optimizations possible.")
    else:
        insights.append("Water usage can be optimized. Consider reviewing consumption patterns.")
    
    if water_saved > 100:
        insights.append(f"You've saved {water_saved:.0f}L compared to baseline usage.")
    
    if avg_daily < 500:
        insights.append("Daily consumption is below average. Great conservation effort!")
    elif avg_daily > 800:
        insights.append("Daily consumption is high. Look for ways to reduce usage.")
    
    return jsonify({
        "period": period,
        "days": days,
        "total_usage_liters": round(total_usage, 1),
        "average_daily_liters": round(avg_daily, 1),
        "water_saved_liters": round(water_saved, 1),
        "savings_percent": round(savings_percent, 1),
        "efficiency_percent": round(efficiency, 1),
        "insights": insights,
        "explanation": {
            "efficiency": "Calculated based on water level stability and usage patterns",
            "savings": "Compared to baseline usage without conservation measures",
            "method": "Simple comparison with 15% higher baseline consumption",
        },
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    }), HTTP_OK
