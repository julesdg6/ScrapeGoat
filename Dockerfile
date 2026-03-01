FROM python:3.11-slim

WORKDIR /app

# Install system dependencies required by some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Ensure pip build tools are up to date.
# NOTE: do NOT upgrade setuptools here -- setuptools>=80 removes pkg_resources,
# which openai-whisper's setup.py requires. The base image ships setuptools<80
# (which has pkg_resources and satisfies openai-whisper's >=65 constraint).
# setuptools_scm is needed by openai-whisper's build backend.
# --no-build-isolation (below) reuses this global env so pip never spins up
# an isolated build env that would reinstall a newer setuptools.
RUN pip install --no-cache-dir --upgrade pip wheel setuptools-scm

# Copy and install Python dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir --no-build-isolation -r requirements.txt

# Copy application files
COPY scrapeGPT_gradio_app.py .
COPY scrapeGPT.py .
COPY db.json .

# Persistent data directory
RUN mkdir -p /data /app/tmp/local_qdrant

EXPOSE 7860

ENV OLLAMA_HOST=http://ollama:11434 \
    OLLAMA_MODEL=qwen:0.5b \
    GRADIO_PORT=7860 \
    DB_PATH=/data/db.json \
    CONFIG_PATH=/data/config.json

CMD ["python", "scrapeGPT_gradio_app.py"]
