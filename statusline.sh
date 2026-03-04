#!/bin/bash
STATUS_FILE="/tmp/pomo.status"
JSON=$(cat)
PCT=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0 | floor')

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
  IFS='|' read -r LABEL END_TIME _ < "$STATUS_FILE"
  if [[ "$LABEL" != "transitioning" ]]; then
    REMAINING=$(( END_TIME - $(date +%s) ))
    if [ "$REMAINING" -gt 0 ]; then
      if [[ "$LABEL" == "long break" ]]; then
        TOTAL=900; EMOJI="🍏"; COLOR="\033[32m"
      elif [[ "$LABEL" == *break* ]]; then
        TOTAL=300; EMOJI="🍏"; COLOR="\033[32m"
      else
        TOTAL=1500; EMOJI="🍅"; COLOR="\033[31m"
      fi
      POMO_PCT=$(( (TOTAL - REMAINING) * 100 / TOTAL ))
      POMO_CBAR=$(build_bar "$POMO_PCT" "$EMOJI" 0 0 "$COLOR")
      printf "%s %s\n" "$CBAR" "$POMO_CBAR"
      exit 0
    fi
  fi
fi

printf "%s\n" "$CBAR"
