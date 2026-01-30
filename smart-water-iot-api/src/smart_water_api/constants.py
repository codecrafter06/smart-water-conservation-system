"""
Constants module - All magic numbers and threshold values.
This eliminates magic numbers throughout the codebase.
"""

# API Version
API_VERSION = "v1"
API_PREFIX = f"/api/{API_VERSION}"

# Water Level Thresholds (in percentage)
WATER_LEVEL_MIN = 0
WATER_LEVEL_MAX = 100
WATER_LEVEL_CRITICAL_LOW = 10
WATER_LEVEL_WARNING_LOW = 20
WATER_LEVEL_WARNING_HIGH = 85
WATER_LEVEL_OVERFLOW_THRESHOLD = 95

# Flow Rate Thresholds (in liters per minute)
FLOW_RATE_MIN = 0.0
FLOW_RATE_MAX = 100.0
FLOW_RATE_NORMAL_MAX = 15.0
FLOW_RATE_LEAKAGE_THRESHOLD = 0.5  # Flow when tank should be stable
FLOW_RATE_HIGH_USAGE = 20.0

# Time Constants (in seconds)
SENSOR_DATA_EXPIRY = 300  # 5 minutes
ANALYTICS_CACHE_TTL = 60  # 1 minute

# Status Codes
STATUS_NORMAL = "normal"
STATUS_WARNING = "warning"
STATUS_CRITICAL = "critical"
STATUS_OVERFLOW_RISK = "overflow_risk"
STATUS_LEAKAGE_DETECTED = "leakage_detected"

# Alert Priorities
ALERT_PRIORITY_LOW = 1
ALERT_PRIORITY_MEDIUM = 2
ALERT_PRIORITY_HIGH = 3
ALERT_PRIORITY_CRITICAL = 4

# Alert Types
ALERT_TYPE_OVERFLOW = "overflow"
ALERT_TYPE_LEAKAGE = "leakage"
ALERT_TYPE_LOW_WATER = "low_water"
ALERT_TYPE_HIGH_FLOW = "high_flow"
ALERT_TYPE_SENSOR_OFFLINE = "sensor_offline"

# HTTP Status Codes (for clarity)
HTTP_OK = 200
HTTP_CREATED = 201
HTTP_BAD_REQUEST = 400
HTTP_NOT_FOUND = 404
HTTP_INTERNAL_ERROR = 500

# Validation Limits
DEVICE_ID_MAX_LENGTH = 50
TANK_ID_MAX_LENGTH = 50
TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%SZ"

# Firebase Collections
COLLECTION_SENSORS = "sensors"
COLLECTION_READINGS = "sensor_readings"
COLLECTION_ALERTS = "alerts"
COLLECTION_ANALYTICS = "analytics"

# Default Values
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
DEFAULT_ANALYTICS_DAYS = 7
