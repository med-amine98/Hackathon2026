FROM python:3.11-slim

# Never write .pyc files back into /app - it's bind-mounted to the host in
# docker-compose.yml (dev hot-reload), and stray bytecode cached there can
# in rare cases get picked up instead of freshly-edited source, which is
# exactly the kind of "my code is right but the container disagrees" bug
# that's a pain to track down.
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# libpq for psycopg2, gcc for building wheels that need it
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create non-root user
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
