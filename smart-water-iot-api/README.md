# Smart Water IoT API

A Flask-based REST API for the Smart Water Conservation System. This backend receives sensor data from IoT devices, detects anomalies (leakage, overflow), stores data, and provides analytics for the Flutter dashboard.

## 🏗️ Architecture

```
IoT Sensors → Flask REST API → Firebase Firestore → Flutter App
```

### Project Structure

```
smart-water-iot-api/
├── src/
│   └── smart_water_api/
│       ├── __init__.py          # Package initialization
│       ├── app_factory.py       # Flask application factory
│       ├── config.py            # Environment configuration
│       ├── constants.py         # All thresholds and magic numbers
│       ├── extensions.py        # Flask extensions
│       ├── api/
│       │   ├── routes.py        # REST API endpoints
│       │   └── schemas.py       # Request/response schemas
│       ├── services/
│       │   ├── sensor_service.py    # Sensor data operations
│       │   ├── analytics_service.py # Analytics calculations
│       │   └── alert_service.py     # Anomaly detection
│       ├── utils/
│       │   └── validators.py    # Input validation
│       └── errors/
│           ├── exceptions.py    # Custom exceptions
│           └── handlers.py      # Error handlers
├── tests/
│   ├── conftest.py              # Test fixtures
│   └── test_api.py              # API tests
├── run.py                       # Application entry point
├── requirements.txt             # Python dependencies
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Python 3.9 or higher
- pip (Python package manager)

### Installation

1. **Clone or navigate to the project:**
   ```bash
   cd smart-water-iot-api
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the development server:**
   ```bash
   python run.py
   ```

5. **Verify it's running:**
   ```
   Open http://localhost:5000/health in your browser
   ```

## 📡 API Endpoints

### Health Check

```http
GET /health
```

Returns API health status.

### Sensor Data Ingestion

```http
POST /api/v1/sensors/ingest
Content-Type: application/json

{
  "device_id": "SENSOR-001",
  "tank_id": "TANK-MAIN",
  "water_level_percent": 65.5,
  "flow_rate_lpm": 5.2,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Live Dashboard

```http
GET /api/v1/dashboard/live
```

Returns current sensor readings, status, and active alerts.

### Daily Analytics

```http
GET /api/v1/analytics/daily?days=7
```

Returns daily aggregated water usage data for charts.

### Weekly Summary

```http
GET /api/v1/analytics/weekly
```

Returns weekly consumption summary.

### Alerts

```http
GET /api/v1/alerts?limit=50&active_only=false
```

Returns all or active alerts.

## 🔍 Alert Detection Rules

| Alert Type | Condition | Priority |
|------------|-----------|----------|
| **Overflow Risk** | Water level ≥ 95% | Critical |
| **High Water** | Water level ≥ 85% | High |
| **Low Water** | Water level ≤ 20% | Medium |
| **Critical Low** | Water level ≤ 10% | Critical |
| **Leakage** | Continuous low flow | Medium |
| **High Flow** | Flow rate ≥ 20 L/min | High |

## 🧪 Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=src/smart_water_api

# Run specific test class
pytest tests/test_api.py::TestSensorIngestEndpoint -v
```

## 🌐 Deployment

### Local Development

```bash
python run.py
```

### Production (Gunicorn)

```bash
gunicorn "src.smart_water_api.app_factory:create_app()" -b 0.0.0.0:8000
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_ENV` | Environment mode | `development` |
| `SECRET_KEY` | Flask secret key | (dev key) |
| `LOG_LEVEL` | Logging level | `INFO` |
| `CORS_ORIGINS` | Allowed origins | `*` |
| `FIREBASE_PROJECT_ID` | Firebase project | (optional) |

### Replit Deployment

1. Import the repository to Replit
2. Set up a Python repl
3. Add environment variables in Secrets
4. Run `python run.py`

### AWS Elastic Beanstalk

1. Create `Procfile`:
   ```
   web: gunicorn "src.smart_water_api.app_factory:create_app()" -b 0.0.0.0:8000
   ```
2. Deploy using EB CLI:
   ```bash
   eb init -p python-3.9 smart-water-api
   eb create smart-water-env
   ```

## 📝 Clean Code Principles

This codebase follows clean code principles:

- ✅ **No magic numbers** - All thresholds in `constants.py`
- ✅ **Meaningful names** - Clear function and variable names
- ✅ **Single responsibility** - Each function/class has one purpose
- ✅ **DRY principle** - Reusable services and utilities
- ✅ **PEP 8 formatting** - Consistent Python style
- ✅ **Minimal comments** - Code explains "what", comments explain "why"

## 📄 License

MIT License - See LICENSE file for details.
