#!/bin/bash
# Wait while command succeeds (exit 0), stop when it fails
CMD="$1"
INTERVAL="${2:-30}"

while eval "$CMD"; do
  echo "$(date +%H:%M:%S) still going..."
  sleep "$INTERVAL"
done
echo "$(date +%H:%M:%S) done"
