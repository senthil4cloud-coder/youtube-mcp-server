# Use official Python runtime as base image
FROM python:3.14-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY app.py .
COPY youtube_mcp_server.py .
COPY .env.example .env.example

# Copy requirements (install from venv or pip freeze)
# For now, we'll install the key dependencies
RUN pip install --no-cache-dir \
    fastmcp==3.4.2 \
    mcp==1.27.2 \
    google-api-python-client==2.197.0 \
    google-auth==2.53.0 \
    google-auth-httplib2==0.4.0 \
    requests==2.34.2 \
    python-dotenv==1.2.2 \
    pydantic==2.13.4 \
    uvicorn==0.49.0

# Cloud Run requires the service to listen on port 8080
EXPOSE 8080

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Run the Cloud Run compatible app
CMD ["python", "-u", "app.py"]
