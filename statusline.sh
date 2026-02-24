#!/bin/bash
STATUS_FILE="/tmp/pomo.status"
JSON=$(cat)
PCT=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0 | floor')

# Build context bar (10 blocks)
FILLED=$((PCT / 10))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# Color context bar
if [ "$PCT" -ge 70 ]; then
  COLOR="\033[31m"
elif [ "$PCT" -ge 50 ]; then
  COLOR="\033[38;5;226m"
else
  COLOR="\033[32m"
fi
CBAR="${COLOR}${BAR}\033[0m"

if [ -f "$STATUS_FILE" ]; then
  IFS='|' read -r LABEL END_TIME ROUND < "$STATUS_FILE"
  if [[ "$LABEL" != "transitioning" ]]; then
    NOW=$(date +%s)
    REMAINING=$((END_TIME - NOW))
    if [ "$REMAINING" -gt 0 ]; then
      # Determine duration based on label
      if [[ "$LABEL" == "long break" ]]; then
        TOTAL=900
      elif [[ "$LABEL" == *break* ]]; then
        TOTAL=300
      else
        TOTAL=1500
      fi
      ELAPSED=$((TOTAL - REMAINING))
      POMO_FILLED=$((ELAPSED * 10 / TOTAL))
      [ "$POMO_FILLED" -lt 0 ] && POMO_FILLED=0
      [ "$POMO_FILLED" -gt 10 ] && POMO_FILLED=10
      POMO_EMPTY=$((10 - POMO_FILLED))
      POMO_BAR=""
      for ((i=0; i<POMO_FILLED; i++)); do POMO_BAR+="█"; done
      for ((i=0; i<POMO_EMPTY; i++)); do POMO_BAR+="░"; done
      # Show CURRENT: tomato for work, apple for break
      if [[ "$LABEL" == *break* ]]; then
        POMO_CBAR="🍏 \033[32m${POMO_BAR}\033[0m"
      else
        POMO_CBAR="🍅 \033[31m${POMO_BAR}\033[0m"
      fi
      printf "🧠 $CBAR $POMO_CBAR\n"
      exit 0
    fi
  fi
fi

printf "🧠 $CBAR\n"
