#!/bin/bash
STATUS_FILE="/tmp/pomo.status"
SPEND_CAP=50
JSON=$(cat)
PCT=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0 | floor')

TODAY=$(date +%Y-%m-%d)
SPEND=$(curl -s -L "https://sdlc-llm.ukg.int/user/daily/activity?start_date=$TODAY&end_date=$TODAY" \
  -H "x-litellm-api-key: ${ANTHROPIC_AUTH_TOKEN}" --cacert ~/.claude/ukg.pem 2>/dev/null | \
  jq -r '.results[0].metrics.spend // 0' 2>/dev/null)

SPEND_PCT=$(echo "$SPEND $SPEND_CAP" | awk '{printf "%.0f", $1/$2*100}')
[ "$SPEND_PCT" -gt 100 ] && SPEND_PCT=100
[ "$PCT" -gt 100 ] && PCT=100

# Build progress bar: emoji + 10-block bar with color thresholds (or fixed color)
build_bar() {
  local pct=$1 emoji=$2 yellow=$3 red=$4 fixed_color=$5
  pct=$(( pct < 0 ? 0 : pct > 100 ? 100 : pct ))
  local blocks=$((pct / 10))
  local color
  if [ -n "$fixed_color" ]; then color="$fixed_color"
  elif [ "$pct" -ge "$red" ]; then color="\033[31m"
  elif [ "$pct" -ge "$yellow" ]; then color="\033[38;5;226m"
  else color="\033[32m"
  fi
  printf "%s ${color}%s\033[0m" "$emoji" "$(printf '█%.0s' $(seq 1 $blocks))$(printf '░%.0s' $(seq 1 $((10-blocks))))"
}

CBAR=$(build_bar "$PCT" "🧠" 50 70)

if [ -f "$STATUS_FILE" ]; then
  IFS='|' read -r LABEL END_TIME ROUND < "$STATUS_FILE"
  if [[ "$LABEL" != "transitioning" ]]; then
    NOW=$(date +%s)
    REMAINING=$((END_TIME - NOW))
    if [ "$REMAINING" -gt 0 ]; then
      if [[ "$LABEL" == "long break" ]]; then TOTAL=900; elif [[ "$LABEL" == *break* ]]; then TOTAL=300; else TOTAL=1500; fi
      ELAPSED=$((TOTAL - REMAINING))
      POMO_PCT=$((ELAPSED * 100 / TOTAL))
      [ "$POMO_PCT" -lt 0 ] && POMO_PCT=0
      [ "$POMO_PCT" -gt 100 ] && POMO_PCT=100
      if [[ "$LABEL" == *break* ]]; then EMOJI="🍏"; COLOR="\033[32m"; else EMOJI="🍅"; COLOR="\033[31m"; fi
      POMO_CBAR=$(build_bar "$POMO_PCT" "$EMOJI" 0 0 "$COLOR")
      SPEND_BAR=$(build_bar "$SPEND_PCT" "💰" 60 80)
      printf "%s %s %s\n" "$CBAR" "$SPEND_BAR" "$POMO_CBAR"
      exit 0
    fi
  fi
fi

SPEND_BAR=$(build_bar "$SPEND_PCT" "💰" 60 80)
printf "%s %s\n" "$CBAR" "$SPEND_BAR"
