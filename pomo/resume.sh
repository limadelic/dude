#!/bin/bash
# Resume watching pomo - loops through all phases until stopped
STATUS_FILE="/tmp/pomo.status"

if [ ! -f "$STATUS_FILE" ]; then
  echo "no active pomo"
  exit 1
fi

while [ -f "$STATUS_FILE" ]; do
  IFS='|' read -r LABEL END_TIME ROUND < "$STATUS_FILE"

  # Wait for transition to complete
  if [[ "$LABEL" == "transitioning" ]]; then
    sleep 1
    continue
  fi

  NOW=$(date +%s)
  REMAINING=$((END_TIME - NOW))

  if [ "$REMAINING" -gt 0 ]; then
    echo "$(date +%H:%M:%S) pomo: $LABEL (round $ROUND), $REMAINING sec left"
    sleep "$REMAINING"
    echo "$(date +%H:%M:%S) pomo done: $LABEL"
    sleep 2
  else
    sleep 1
  fi
done

echo "$(date +%H:%M:%S) pomo stopped"
