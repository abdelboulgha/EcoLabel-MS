FROM python:3.11-slim

WORKDIR /app

# -------- System dependencies --------
# Needed for SQLAlchemy + psycopg2 (if used in DB layer)
#RUN apt-get update && apt-get install -y \
#    gcc \
#    libpq-dev \
#    curl \
#    && rm -rf /var/lib/apt/lists/*

# -------- Python dependencies --------
RUN pip install --upgrade pip setuptools wheel

# Copy requirements first (better Docker cache)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# -------- Application code --------
COPY . .

# -------- Expose FastAPI port --------
EXPOSE 8004

# -------- Start FastAPI --------
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8004"]
