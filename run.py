"""
run.py – Application Entry Point
Run locally: python run.py
Production (Gunicorn): gunicorn -b :8080 run:app
"""

from app import create_app

app = create_app()

if __name__ == '__main__':
    # Debug mode only for local development — never in production!
    app.run(debug=True, host='0.0.0.0', port=5000)
