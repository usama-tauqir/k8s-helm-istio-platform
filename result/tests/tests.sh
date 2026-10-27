#!/bin/sh
set -e

echo "Waiting for vote and result..."
until curl -sf http://vote > /dev/null; do sleep 1; done
until curl -sf http://result > /dev/null; do sleep 1; done

echo "Casting a vote for 'b'..."
curl -sf -X POST --data "vote=b" http://vote > /dev/null

echo "Waiting for the worker to write it to Postgres..."
for i in $(seq 1 30); do
  count=$(PGPASSWORD=postgres psql -h db -U postgres -tAc \
    "SELECT COUNT(*) FROM votes WHERE vote='b';" 2>/dev/null || echo 0)
  if [ "${count:-0}" -ge 1 ]; then
    echo "PASS: vote reached the database"
    exit 0
  fi
  sleep 1
done

echo "FAIL: vote never reached the database"
exit 1