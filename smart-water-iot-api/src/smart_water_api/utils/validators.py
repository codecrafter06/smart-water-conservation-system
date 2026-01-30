"""
Input validation utilities.
Provides reusable validation functions for sensor data.
"""

from datetime import datetime
from typing import Any, Optional
from ..constants import (
    WATER_LEVEL_MIN,
    WATER_LEVEL_MAX,
    FLOW_RATE_MIN,
    FLOW_RATE_MAX,
    DEVICE_ID_MAX_LENGTH,
    TANK_ID_MAX_LENGTH,
    TIMESTAMP_FORMAT,
)
from ..errors.exceptions import ValidationError


def validate_sensor_data(data: dict) -> dict:
    """
    Validate incoming sensor data.
    
    Args:
        data: Dictionary containing sensor reading data
        
    Returns:
        Validated and normalized data dictionary
        
    Raises:
        ValidationError: If any field fails validation
    """
    validated = {}
    
    # Validate device_id
    device_id = data.get("device_id")
    if not device_id:
        raise ValidationError("device_id is required", field="device_id")
    if not isinstance(device_id, str):
        raise ValidationError("device_id must be a string", field="device_id")
    if len(device_id) > DEVICE_ID_MAX_LENGTH:
        raise ValidationError(
            f"device_id must be at most {DEVICE_ID_MAX_LENGTH} characters",
            field="device_id"
        )
    validated["device_id"] = device_id.strip()
    
    # Validate tank_id
    tank_id = data.get("tank_id")
    if not tank_id:
        raise ValidationError("tank_id is required", field="tank_id")
    if not isinstance(tank_id, str):
        raise ValidationError("tank_id must be a string", field="tank_id")
    if len(tank_id) > TANK_ID_MAX_LENGTH:
        raise ValidationError(
            f"tank_id must be at most {TANK_ID_MAX_LENGTH} characters",
            field="tank_id"
        )
    validated["tank_id"] = tank_id.strip()
    
    # Validate water_level_percent
    water_level = data.get("water_level_percent")
    if water_level is None:
        raise ValidationError("water_level_percent is required", field="water_level_percent")
    try:
        water_level = float(water_level)
    except (TypeError, ValueError):
        raise ValidationError(
            "water_level_percent must be a number",
            field="water_level_percent"
        )
    if water_level < WATER_LEVEL_MIN or water_level > WATER_LEVEL_MAX:
        raise ValidationError(
            f"water_level_percent must be between {WATER_LEVEL_MIN} and {WATER_LEVEL_MAX}",
            field="water_level_percent"
        )
    validated["water_level_percent"] = round(water_level, 2)
    
    # Validate flow_rate_lpm
    flow_rate = data.get("flow_rate_lpm")
    if flow_rate is None:
        raise ValidationError("flow_rate_lpm is required", field="flow_rate_lpm")
    try:
        flow_rate = float(flow_rate)
    except (TypeError, ValueError):
        raise ValidationError(
            "flow_rate_lpm must be a number",
            field="flow_rate_lpm"
        )
    if flow_rate < FLOW_RATE_MIN or flow_rate > FLOW_RATE_MAX:
        raise ValidationError(
            f"flow_rate_lpm must be between {FLOW_RATE_MIN} and {FLOW_RATE_MAX}",
            field="flow_rate_lpm"
        )
    validated["flow_rate_lpm"] = round(flow_rate, 2)
    
    # Validate timestamp
    timestamp = data.get("timestamp")
    if timestamp:
        validated["timestamp"] = validate_timestamp(timestamp)
    else:
        validated["timestamp"] = datetime.utcnow().isoformat() + "Z"
    
    return validated


def validate_timestamp(timestamp: Any) -> str:
    """
    Validate and normalize timestamp.
    
    Args:
        timestamp: Timestamp string in ISO format
        
    Returns:
        Normalized timestamp string
        
    Raises:
        ValidationError: If timestamp format is invalid
    """
    if not isinstance(timestamp, str):
        raise ValidationError("timestamp must be a string", field="timestamp")
    
    try:
        # Try parsing ISO format
        dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        return dt.strftime(TIMESTAMP_FORMAT)
    except ValueError:
        pass
    
    try:
        # Try parsing our expected format
        dt = datetime.strptime(timestamp, TIMESTAMP_FORMAT)
        return timestamp
    except ValueError:
        raise ValidationError(
            f"timestamp must be in ISO format or {TIMESTAMP_FORMAT}",
            field="timestamp"
        )
