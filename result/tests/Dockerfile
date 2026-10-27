FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY tests.sh .
# strip Windows line endings in case the file was saved with CRLF
RUN sed -i 's/\r$//' tests.sh && chmod +x tests.sh

CMD ["./tests.sh"]