# Stage 1: dependencies install karo
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# Stage 2: final image
FROM python:3.12-slim
WORKDIR /usr/local/app

COPY --from=builder /install /usr/local

RUN useradd --create-home --uid 10001 app
COPY --chown=app:app . .
USER 10001

EXPOSE 8080

# curl ki jagah Python se hi healthcheck
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')" || exit 1

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]