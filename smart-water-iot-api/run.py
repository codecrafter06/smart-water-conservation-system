"""
Application entry point.
Run this file to start the Flask development server.
"""

from src.smart_water_api.app_factory import create_app

app = create_app()

if __name__ == "__main__":
    # Run the development server
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
    )
