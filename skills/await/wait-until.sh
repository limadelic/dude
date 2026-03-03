#!/bin/bash
# Wait until command succeeds (exit 0)
CMD="$1"
INTERVAL="${2:-30}"

while ! eval "$CMD"; do
  echo "$(date +%H:%M:%S) waiting..."
  sleep "$INTERVAL"
done
echo "$(date +%H:%M:%S) done"
