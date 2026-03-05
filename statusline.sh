#!/bin/bash
POMO="/tmp/pomo.status"
SPEND_CAP=200
JSON=$(cat)

context() {
  echo "$JSON" | jq -r '.context_window.used_percentage // 0 | floor'
}

color() {
  local pct=$1 lo=$2 hi=$3 fixed=$4
  [ -n "$fixed" ] && { echo "$fixed"; return; }
  [ "$pct" -ge "$hi" ] && { echo "\033[31m"; return; }
  [ "$pct" -ge "$lo" ] && { echo "\033[38;5;226m"; return; }
  echo "\033[32m"
}

blocks() {
  local n=$((($1 < 0 ? 0 : $1 > 100 ? 100 : $1) / 10))
  local e=$((10 - n))
  [ $n -gt 0 ] && printf '█%.0s' $(seq 1 $n)
  [ $e -gt 0 ] && printf '░%.0s' $(seq 1 $e)
}

bar() {
  local pct=$1 icon=$2 clr
  clr=$(color "$pct" "$3" "$4" "$5")
  printf "%s ${clr}%s\033[0m" "$icon" "$(blocks "$pct")"
}

spend() {
  local today=$(date +%Y-%m-%d)
  local s=$(curl -s -L "https://sdlc-llm.ukg.int/user/daily/activity?start_date=$today&end_date=$today" \
    -H "x-litellm-api-key: ${ANTHROPIC_AUTH_TOKEN}" --cacert ~/.claude/ukg.pem 2>/dev/null | \
    jq -r '.results[0].metrics.spend // 0' 2>/dev/null)
  local pct=$(echo "$s $SPEND_CAP" | awk '{printf "%.0f", $1/$2*100}')
  pct=${pct:-0}
  [ "$pct" -gt 100 ] && pct=100
  bar "$pct" "💰" 60 80
}

pomo_type() {
  [[ "$1" == "long break" ]] && { echo "900 🍏 \033[32m"; return; }
  [[ "$1" == *break* ]]      && { echo "300 🍏 \033[32m"; return; }
  echo "1500 🍅 \033[31m"
}

pomo() {
  [ -f "$POMO" ] || return 1
  IFS='|' read -r label end _ < "$POMO"
  [[ "$label" == "transitioning" ]] && return 1
  local left=$(( end - $(date +%s) ))
  [ "$left" -le 0 ] && return 1
  read -r total icon clr <<< "$(pomo_type "$label")"
  bar "$(( (total - left) * 100 / total ))" "$icon" 0 0 "$clr"
}

model_emoji() {
  local m=$(echo "$JSON" | jq -r '.model // ""')
  case "$m" in
    *haiku*) echo "🐸" ;;
    *opus*)  echo "🎭" ;;
    *)       echo "🎸" ;;
  esac
}

PCT=$(context)
CBAR=$(bar "$PCT" "🧠" 50 70)
SBAR=$(spend)
MODEL=$(model_emoji)
PBAR=$(pomo) && printf "%s %s %s %s\n" "$CBAR" "$SBAR" "$PBAR" "$MODEL" || printf "%s %s %s\n" "$CBAR" "$SBAR" "$MODEL"
