"""
Alert Service - Detects water anomalies like leakage and overflow.
Implements smart detection rules based on sensor thresholds.
"""

import logging
from datetime import datetime
from typing import Dict, List, Any, Optional

from ..constants import (
    WATER_LEVEL_OVERFLOW_THRESHOLD,
    WATER_LEVEL_CRITICAL_LOW,
    WATER_LEVEL_WARNING_LOW,
    WATER_LEVEL_WARNING_HIGH,
    FLOW_RATE_LEAKAGE_THRESHOLD,
    FLOW_RATE_HIGH_USAGE,
    FLOW_RATE_NORMAL_MAX,
    STATUS_NORMAL,
    STATUS_WARNING,
    STATUS_CRITICAL,
    STATUS_OVERFLOW_RISK,
    STATUS_LEAKAGE_DETECTED,
    ALERT_TYPE_OVERFLOW,
    ALERT_TYPE_LEAKAGE,
    ALERT_TYPE_LOW_WATER,
    ALERT_TYPE_HIGH_FLOW,
    ALERT_PRIORITY_LOW,
    ALERT_PRIORITY_MEDIUM,
    ALERT_PRIORITY_HIGH,
    ALERT_PRIORITY_CRITICAL,
)

logger = logging.getLogger(__name__)


class AlertService:
    """
    Service for detecting water anomalies and generating alerts.
    Analyzes sensor readings to detect leakage, overflow, and other issues.
    """
    
    def __init__(self):
        """Initialize the alert service with default thresholds."""
        self._alerts: List[Dict] = []
    
    def analyze_reading(self, reading: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze a sensor reading for anomalies.
        
        Args:
            reading: Validated sensor data dictionary
            
        Returns:
            Analysis result with status and any generated alerts
        """
        water_level = reading.get("water_level_percent", 0)
        flow_rate = reading.get("flow_rate_lpm", 0)
        device_id = reading.get("device_id", "unknown")
        tank_id = reading.get("tank_id", "unknown")
        
        alerts = []
        status = STATUS_NORMAL
        status_message = "All systems normal"
        
        # Check for overflow risk
        overflow_alert = self._check_overflow_risk(water_level, device_id, tank_id)
        if overflow_alert:
            alerts.append(overflow_alert)
            status = STATUS_OVERFLOW_RISK
            status_message = f"Overflow risk detected - Water level at {water_level}%"
        
        # Check for leakage
        leakage_alert = self._check_leakage(water_level, flow_rate, device_id, tank_id)
        if leakage_alert:
            alerts.append(leakage_alert)
            if status == STATUS_NORMAL:
                status = STATUS_LEAKAGE_DETECTED
                status_message = "Potential leakage detected"
        
        # Check for low water level
        low_water_alert = self._check_low_water(water_level, device_id, tank_id)
        if low_water_alert:
            alerts.append(low_water_alert)
            if status == STATUS_NORMAL:
                status = STATUS_WARNING if water_level >= WATER_LEVEL_CRITICAL_LOW else STATUS_CRITICAL
                status_message = f"Low water level - {water_level}%"
        
        # Check for high flow rate
        high_flow_alert = self._check_high_flow(flow_rate, device_id, tank_id)
        if high_flow_alert:
            alerts.append(high_flow_alert)
            if status == STATUS_NORMAL:
                status = STATUS_WARNING
                status_message = f"High flow rate - {flow_rate} L/min"
        
        # Store alerts
        self._alerts.extend(alerts)
        
        result = {
            "status": status,
            "status_message": status_message,
            "water_level_percent": water_level,
            "flow_rate_lpm": flow_rate,
            "alerts_count": len(alerts),
            "alerts": alerts,
        }
        
        if alerts:
            logger.warning(
                f"Alerts generated for {device_id}: {[a['type'] for a in alerts]}"
            )
        
        return result
    
    def _check_overflow_risk(
        self, 
        water_level: float, 
        device_id: str, 
        tank_id: str
    ) -> Optional[Dict]:
        """Check if water level indicates overflow risk."""
        if water_level >= WATER_LEVEL_OVERFLOW_THRESHOLD:
            return self._create_alert(
                alert_type=ALERT_TYPE_OVERFLOW,
                priority=ALERT_PRIORITY_CRITICAL,
                message=f"Tank {tank_id} is at {water_level}% capacity - Overflow imminent!",
                device_id=device_id,
                tank_id=tank_id,
                value=water_level,
                threshold=WATER_LEVEL_OVERFLOW_THRESHOLD,
            )
        elif water_level >= WATER_LEVEL_WARNING_HIGH:
            return self._create_alert(
                alert_type=ALERT_TYPE_OVERFLOW,
                priority=ALERT_PRIORITY_HIGH,
                message=f"Tank {tank_id} water level is high at {water_level}%",
                device_id=device_id,
                tank_id=tank_id,
                value=water_level,
                threshold=WATER_LEVEL_WARNING_HIGH,
            )
        return None
    
    def _check_leakage(
        self, 
        water_level: float, 
        flow_rate: float, 
        device_id: str, 
        tank_id: str
    ) -> Optional[Dict]:
        """
        Check for potential leakage.
        Leakage is suspected when there's flow but water level is stable/dropping.
        """
        # Leakage indicators:
        # 1. Continuous low flow when tank is not being filled/used
        # 2. Flow detected when water level is decreasing unexpectedly
        
        if flow_rate >= FLOW_RATE_LEAKAGE_THRESHOLD and water_level < WATER_LEVEL_WARNING_HIGH:
            # Small but consistent flow might indicate a leak
            if flow_rate < FLOW_RATE_NORMAL_MAX / 2:
                return self._create_alert(
                    alert_type=ALERT_TYPE_LEAKAGE,
                    priority=ALERT_PRIORITY_MEDIUM,
                    message=f"Potential leak detected - Low continuous flow of {flow_rate} L/min",
                    device_id=device_id,
                    tank_id=tank_id,
                    value=flow_rate,
                    threshold=FLOW_RATE_LEAKAGE_THRESHOLD,
                )
        return None
    
    def _check_low_water(
        self, 
        water_level: float, 
        device_id: str, 
        tank_id: str
    ) -> Optional[Dict]:
        """Check for critically low water level."""
        if water_level <= WATER_LEVEL_CRITICAL_LOW:
            return self._create_alert(
                alert_type=ALERT_TYPE_LOW_WATER,
                priority=ALERT_PRIORITY_CRITICAL,
                message=f"Tank {tank_id} water level critically low at {water_level}%",
                device_id=device_id,
                tank_id=tank_id,
                value=water_level,
                threshold=WATER_LEVEL_CRITICAL_LOW,
            )
        elif water_level <= WATER_LEVEL_WARNING_LOW:
            return self._create_alert(
                alert_type=ALERT_TYPE_LOW_WATER,
                priority=ALERT_PRIORITY_MEDIUM,
                message=f"Tank {tank_id} water level low at {water_level}%",
                device_id=device_id,
                tank_id=tank_id,
                value=water_level,
                threshold=WATER_LEVEL_WARNING_LOW,
            )
        return None
    
    def _check_high_flow(
        self, 
        flow_rate: float, 
        device_id: str, 
        tank_id: str
    ) -> Optional[Dict]:
        """Check for abnormally high flow rate."""
        if flow_rate >= FLOW_RATE_HIGH_USAGE:
            return self._create_alert(
                alert_type=ALERT_TYPE_HIGH_FLOW,
                priority=ALERT_PRIORITY_HIGH,
                message=f"Unusually high water flow detected - {flow_rate} L/min",
                device_id=device_id,
                tank_id=tank_id,
                value=flow_rate,
                threshold=FLOW_RATE_HIGH_USAGE,
            )
        return None
    
    def _create_alert(
        self,
        alert_type: str,
        priority: int,
        message: str,
        device_id: str,
        tank_id: str,
        value: float,
        threshold: float,
    ) -> Dict[str, Any]:
        """Create a structured alert object with suggested actions."""
        # Determine suggested action based on alert type
        suggested_action = self._get_suggested_action(alert_type, value, threshold)
        cause = self._get_cause_explanation(alert_type, value, threshold)
        
        return {
            "type": alert_type,
            "priority": priority,
            "priority_label": self._get_priority_label(priority),
            "message": message,
            "device_id": device_id,
            "tank_id": tank_id,
            "detected_value": value,
            "threshold": threshold,
            "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "acknowledged": False,
            "suggested_action": suggested_action,
            "cause": cause,
        }
    
    def _get_suggested_action(self, alert_type: str, value: float, threshold: float) -> str:
        """Get suggested action based on alert type."""
        actions = {
            ALERT_TYPE_OVERFLOW: "Reduce inflow immediately. Stop pump or close inlet valve.",
            ALERT_TYPE_LEAKAGE: f"Check pipeline near {alert_type}. Inspect for visible leaks.",
            ALERT_TYPE_LOW_WATER: "Start pump within 30 minutes. Check water source availability.",
            ALERT_TYPE_HIGH_FLOW: "Monitor usage. Check for open taps or unusual consumption.",
        }
        return actions.get(alert_type, "Monitor the situation and take appropriate action.")
    
    def _get_cause_explanation(self, alert_type: str, value: float, threshold: float) -> str:
        """Get simple cause explanation."""
        causes = {
            ALERT_TYPE_OVERFLOW: f"Water level ({value:.1f}%) exceeded safe threshold ({threshold}%)",
            ALERT_TYPE_LEAKAGE: f"Continuous flow ({value:.1f} L/min) detected without active usage",
            ALERT_TYPE_LOW_WATER: f"Water level ({value:.1f}%) below minimum threshold ({threshold}%)",
            ALERT_TYPE_HIGH_FLOW: f"Flow rate ({value:.1f} L/min) exceeds normal usage ({threshold} L/min)",
        }
        return causes.get(alert_type, "Sensor reading outside normal range")
    
    def _get_priority_label(self, priority: int) -> str:
        """Convert priority number to human-readable label."""
        labels = {
            ALERT_PRIORITY_LOW: "Low",
            ALERT_PRIORITY_MEDIUM: "Medium",
            ALERT_PRIORITY_HIGH: "High",
            ALERT_PRIORITY_CRITICAL: "Critical",
        }
        return labels.get(priority, "Unknown")
    
    def get_all_alerts(self, limit: int = 50) -> List[Dict]:
        """Get all stored alerts, most recent first."""
        sorted_alerts = sorted(
            self._alerts, 
            key=lambda x: x.get("timestamp", ""), 
            reverse=True
        )
        return sorted_alerts[:limit]
    
    def get_active_alerts(self) -> List[Dict]:
        """Get only unacknowledged alerts."""
        return [a for a in self._alerts if not a.get("acknowledged", False)]
    
    def clear_alerts(self):
        """Clear all stored alerts (for testing)."""
        self._alerts = []
