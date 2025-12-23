FROM python:3.11-slim

# -------- System dependencies --------
# psycopg2 needs libpq + gcc
#RUN apt-get update && apt-get install -y \
#    gcc \
#    libpq-dev \
#    curl \
#    && rm -rf /var/lib/apt/lists/*

# -------- Python dependencies --------
RUN pip install --upgrade pip setuptools wheel

# Copy only requirements first (Docker cache optimization)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# -------- Application code --------
# Do NOT copy CSV here (it will be mounted as a volume)
COPY . .

# -------- Expose service port --------
EXPOSE 8003

# -------- Start FastAPI --------
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003"]
