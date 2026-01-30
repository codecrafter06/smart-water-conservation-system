"""
Analytics Service - Provides data aggregation for charts and reports.
Calculates daily/weekly water usage statistics.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict

from ..constants import DEFAULT_ANALYTICS_DAYS
from .sensor_service import SensorService

logger = logging.getLogger(__name__)


class AnalyticsService:
    """
    Service for generating analytics and aggregated data.
    Used for dashboard charts and usage reports.
    """
    
    def __init__(self, sensor_service: SensorService = None):
        """
        Initialize the analytics service.
        
        Args:
            sensor_service: Optional sensor service instance for data access
        """
        self._sensor_service = sensor_service or SensorService()
    
    def get_daily_analytics(self, days: int = DEFAULT_ANALYTICS_DAYS) -> Dict[str, Any]:
        """
        Get daily aggregated water usage data.
        
        Args:
            days: Number of days to include in analytics
            
        Returns:
            Dictionary containing daily analytics data suitable for charts
        """
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        readings = self._sensor_service.get_readings_by_date(start_date, end_date)
        
        # Aggregate data by day
        daily_data = defaultdict(lambda: {
            "readings_count": 0,
            "total_flow": 0.0,
            "avg_water_level": 0.0,
            "max_water_level": 0.0,
            "min_water_level": 100.0,
            "water_levels": [],
        })
        
        for reading in readings:
            try:
                timestamp = reading.get("timestamp", "")
                date_str = timestamp[:10]  # Extract YYYY-MM-DD
                
                water_level = reading.get("water_level_percent", 0)
                flow_rate = reading.get("flow_rate_lpm", 0)
                
                daily_data[date_str]["readings_count"] += 1
                daily_data[date_str]["total_flow"] += flow_rate
                daily_data[date_str]["water_levels"].append(water_level)
                daily_data[date_str]["max_water_level"] = max(
                    daily_data[date_str]["max_water_level"], 
                    water_level
                )
                daily_data[date_str]["min_water_level"] = min(
                    daily_data[date_str]["min_water_level"], 
                    water_level
                )
            except (ValueError, TypeError, KeyError) as e:
                logger.warning(f"Skipping invalid reading: {e}")
                continue
        
        # Calculate averages and format response
        chart_data = []
        for date_str in sorted(daily_data.keys()):
            data = daily_data[date_str]
            levels = data["water_levels"]
            avg_level = sum(levels) / len(levels) if levels else 0
            
            chart_data.append({
                "date": date_str,
                "average_water_level": round(avg_level, 1),
                "max_water_level": round(data["max_water_level"], 1),
                "min_water_level": round(data["min_water_level"], 1),
                "total_flow_liters": round(data["total_flow"], 1),
                "readings_count": data["readings_count"],
            })
        
        # Calculate summary statistics
        total_flow = sum(d["total_flow_liters"] for d in chart_data)
        avg_daily_level = (
            sum(d["average_water_level"] for d in chart_data) / len(chart_data)
            if chart_data else 0
        )
        
        return {
            "period": {
                "start_date": start_date.strftime("%Y-%m-%d"),
                "end_date": end_date.strftime("%Y-%m-%d"),
                "days": days,
            },
            "summary": {
                "total_water_flow_liters": round(total_flow, 1),
                "average_daily_level": round(avg_daily_level, 1),
                "total_readings": sum(d["readings_count"] for d in chart_data),
            },
            "daily_data": chart_data,
        }
    
    def get_weekly_summary(self) -> Dict[str, Any]:
        """
        Get a weekly summary of water usage.
        
        Returns:
            Dictionary with weekly aggregated statistics
        """
        daily_analytics = self.get_daily_analytics(days=7)
        daily_data = daily_analytics.get("daily_data", [])
        
        if not daily_data:
            return {
                "week_start": (datetime.utcnow() - timedelta(days=7)).strftime("%Y-%m-%d"),
                "week_end": datetime.utcnow().strftime("%Y-%m-%d"),
                "total_consumption_liters": 0,
                "average_daily_consumption": 0,
                "peak_consumption_day": None,
                "lowest_consumption_day": None,
            }
        
        # Find peak and lowest consumption days
        sorted_by_flow = sorted(daily_data, key=lambda x: x["total_flow_liters"])
        
        return {
            "week_start": daily_analytics["period"]["start_date"],
            "week_end": daily_analytics["period"]["end_date"],
            "total_consumption_liters": daily_analytics["summary"]["total_water_flow_liters"],
            "average_daily_consumption": round(
                daily_analytics["summary"]["total_water_flow_liters"] / len(daily_data), 1
            ),
            "peak_consumption_day": {
                "date": sorted_by_flow[-1]["date"],
                "liters": sorted_by_flow[-1]["total_flow_liters"],
            },
            "lowest_consumption_day": {
                "date": sorted_by_flow[0]["date"],
                "liters": sorted_by_flow[0]["total_flow_liters"],
            },
        }
    
    def get_hourly_pattern(self) -> Dict[str, Any]:
        """
        Analyze hourly water usage patterns.
        
        Returns:
            Dictionary with hourly usage patterns
        """
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=7)
        
        readings = self._sensor_service.get_readings_by_date(start_date, end_date)
        
        # Aggregate by hour
        hourly_data = defaultdict(lambda: {"total_flow": 0.0, "count": 0})
        
        for reading in readings:
            try:
                timestamp = reading.get("timestamp", "")
                hour = int(timestamp[11:13])  # Extract HH from timestamp
                flow_rate = reading.get("flow_rate_lpm", 0)
                
                hourly_data[hour]["total_flow"] += flow_rate
                hourly_data[hour]["count"] += 1
            except (ValueError, TypeError, IndexError):
                continue
        
        # Calculate average flow per hour
        hourly_pattern = []
        for hour in range(24):
            data = hourly_data[hour]
            avg_flow = data["total_flow"] / data["count"] if data["count"] > 0 else 0
            hourly_pattern.append({
                "hour": hour,
                "hour_label": f"{hour:02d}:00",
                "average_flow_lpm": round(avg_flow, 2),
            })
        
        return {
            "period_days": 7,
            "hourly_pattern": hourly_pattern,
        }
