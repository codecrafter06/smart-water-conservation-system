"""
Sensor Service - Handles sensor data ingestion and retrieval.
Uses mock Firebase for development and testing.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from collections import defaultdict

from ..constants import (
    COLLECTION_READINGS,
    SENSOR_DATA_EXPIRY,
    DEFAULT_PAGE_SIZE,
)
from ..errors.exceptions import FirebaseError, SensorDataError

logger = logging.getLogger(__name__)


class MockFirebaseDB:
    """
    Mock Firebase database for development and testing.
    Stores data in memory with basic query support.
    """
    
    def __init__(self):
        self._collections: Dict[str, List[Dict]] = defaultdict(list)
        self._seed_sample_data()
    
    def _seed_sample_data(self):
        """Seed the database with sample sensor readings."""
        base_time = datetime.utcnow()
        
        # Generate 7 days of sample data
        for day_offset in range(7):
            for hour in range(24):
                timestamp = base_time - timedelta(days=day_offset, hours=hour)
                
                # Simulate realistic water usage patterns
                hour_of_day = timestamp.hour
                
                # Higher usage in morning (6-9) and evening (18-21)
                if 6 <= hour_of_day <= 9:
                    water_level = 60 + (hour_of_day - 6) * 5
                    flow_rate = 8.5 + (hour_of_day % 3)
                elif 18 <= hour_of_day <= 21:
                    water_level = 70 - (hour_of_day - 18) * 5
                    flow_rate = 7.0 + (hour_of_day % 2)
                else:
                    water_level = 65 + (hour_of_day % 10)
                    flow_rate = 2.0 + (hour_of_day % 5) * 0.5
                
                reading = {
                    "device_id": "SENSOR-001",
                    "tank_id": "TANK-MAIN",
                    "water_level_percent": min(95, max(10, water_level)),
                    "flow_rate_lpm": round(flow_rate, 2),
                    "timestamp": timestamp.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "created_at": timestamp.isoformat(),
                }
                self._collections[COLLECTION_READINGS].append(reading)
        
        logger.info(f"Seeded {len(self._collections[COLLECTION_READINGS])} sample readings")
    
    def add(self, collection: str, document: Dict) -> str:
        """Add a document to a collection."""
        doc_id = f"doc_{len(self._collections[collection])}"
        document["_id"] = doc_id
        document["created_at"] = datetime.utcnow().isoformat()
        self._collections[collection].append(document)
        return doc_id
    
    def get_latest(self, collection: str, limit: int = 1) -> List[Dict]:
        """Get the most recent documents from a collection."""
        docs = self._collections[collection]
        sorted_docs = sorted(docs, key=lambda x: x.get("created_at", ""), reverse=True)
        return sorted_docs[:limit]
    
    def get_by_date_range(
        self, 
        collection: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> List[Dict]:
        """Get documents within a date range."""
        results = []
        for doc in self._collections[collection]:
            try:
                doc_time = datetime.fromisoformat(doc.get("created_at", "").replace("Z", "+00:00"))
                if start_date <= doc_time.replace(tzinfo=None) <= end_date:
                    results.append(doc)
            except (ValueError, TypeError):
                continue
        return sorted(results, key=lambda x: x.get("created_at", ""))


# Global mock database instance
_mock_db: Optional[MockFirebaseDB] = None


def get_mock_db() -> MockFirebaseDB:
    """Get or create the mock database instance."""
    global _mock_db
    if _mock_db is None:
        _mock_db = MockFirebaseDB()
    return _mock_db


def reset_mock_db():
    """Reset the mock database (for testing)."""
    global _mock_db
    _mock_db = None


class SensorService:
    """
    Service for handling sensor data operations.
    Provides methods for ingesting and retrieving sensor readings.
    """
    
    def __init__(self, use_mock: bool = True):
        """
        Initialize the sensor service.
        
        Args:
            use_mock: Whether to use mock Firebase (default: True for dev)
        """
        self.use_mock = use_mock
        self._db = get_mock_db() if use_mock else None
    
    def ingest_reading(self, validated_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Store a validated sensor reading.
        
        Args:
            validated_data: Pre-validated sensor data dictionary
            
        Returns:
            Dictionary with ingestion result and any detected alerts
        """
        try:
            # Store the reading
            doc_id = self._db.add(COLLECTION_READINGS, validated_data.copy())
            
            logger.info(
                f"Ingested reading from device {validated_data['device_id']}: "
                f"level={validated_data['water_level_percent']}%, "
                f"flow={validated_data['flow_rate_lpm']}L/min"
            )
            
            return {
                "success": True,
                "document_id": doc_id,
                "device_id": validated_data["device_id"],
                "tank_id": validated_data["tank_id"],
                "timestamp": validated_data["timestamp"],
            }
            
        except Exception as e:
            logger.error(f"Failed to ingest sensor data: {str(e)}")
            raise FirebaseError(f"Failed to store sensor reading: {str(e)}")
    
    def get_latest_readings(self, limit: int = DEFAULT_PAGE_SIZE) -> List[Dict]:
        """
        Get the most recent sensor readings.
        
        Args:
            limit: Maximum number of readings to return
            
        Returns:
            List of recent sensor readings
        """
        try:
            readings = self._db.get_latest(COLLECTION_READINGS, limit)
            # Remove internal fields before returning
            return [
                {k: v for k, v in r.items() if not k.startswith("_")}
                for r in readings
            ]
        except Exception as e:
            logger.error(f"Failed to retrieve readings: {str(e)}")
            raise FirebaseError(f"Failed to retrieve sensor readings: {str(e)}")
    
    def get_readings_by_date(
        self, 
        start_date: datetime, 
        end_date: datetime
    ) -> List[Dict]:
        """
        Get sensor readings within a date range.
        
        Args:
            start_date: Start of the date range
            end_date: End of the date range
            
        Returns:
            List of sensor readings in the date range
        """
        try:
            readings = self._db.get_by_date_range(
                COLLECTION_READINGS, 
                start_date, 
                end_date
            )
            return [
                {k: v for k, v in r.items() if not k.startswith("_")}
                for r in readings
            ]
        except Exception as e:
            logger.error(f"Failed to retrieve readings by date: {str(e)}")
            raise FirebaseError(f"Failed to retrieve sensor readings: {str(e)}")
