# ══════════════════════════════════════════════════════════════════════════════
# Dockerfile – Container image for Kubernetes / Cloud Run deployment
# Build:  docker build -t expense-tracker .
# Run:    docker run -p 8080:8080 --env-file .env expense-tracker
# ══════════════════════════════════════════════════════════════════════════════

# Use official slim Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for PyMySQL / compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (Docker layer caching: only reinstall if changed)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create uploads directory
RUN mkdir -p app/static/uploads instance

# Expose port (Cloud Run and GKE expect 8080)
EXPOSE 8080

# Environment variables with defaults (override at runtime)
ENV FLASK_ENV=production
ENV PORT=8080

# Run Gunicorn WSGI server
# -w 2 = 2 worker processes (adjust based on CPU)
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "--timeout", "120", "run:app"]
