#!/bin/bash
STATUS_FILE="/tmp/pomo.status"

ctx_pct() {
  cat | jq -r '.context_window.used_percentage // 0 | floor'
}

bar_color() {
  local pct=$1 yellow=$2 red=$3 fixed=$4
  [ -n "$fixed" ] && { echo "$fixed"; return; }
  [ "$pct" -ge "$red" ] && { echo "\033[31m"; return; }
  [ "$pct" -ge "$yellow" ] && { echo "\033[38;5;226m"; return; }
  echo "\033[32m"
}

bar_blocks() {
  local blocks=$((($1 < 0 ? 0 : $1 > 100 ? 100 : $1) / 10))
  printf '█%.0s' $(seq 1 $blocks)
  printf '░%.0s' $(seq 1 $((10 - blocks)))
}

build_bar() {
  local pct=$1 emoji=$2 color
  color=$(bar_color "$pct" "$3" "$4" "$5")
  printf "%s ${color}%s\033[0m" "$emoji" "$(bar_blocks "$pct")"
}

pomo_props() {
  [[ "$1" == "long break" ]] && { echo "900 🍏 \033[32m"; return; }
  [[ "$1" == *break* ]]      && { echo "300 🍏 \033[32m"; return; }
  echo "1500 🍅 \033[31m"
}

pomo_bar() {
  [ -f "$STATUS_FILE" ] || return 1
  IFS='|' read -r LABEL END_TIME _ < "$STATUS_FILE"
  [[ "$LABEL" == "transitioning" ]] && return 1
  local remaining=$(( END_TIME - $(date +%s) ))
  [ "$remaining" -le 0 ] && return 1
  read -r TOTAL EMOJI COLOR <<< "$(pomo_props "$LABEL")"
  build_bar "$(( (TOTAL - remaining) * 100 / TOTAL ))" "$EMOJI" 0 0 "$COLOR"
}

PCT=$(ctx_pct)
CBAR=$(build_bar "$PCT" "🧠" 50 70)
PBAR=$(pomo_bar) && printf "%s %s\n" "$CBAR" "$PBAR" || printf "%s\n" "$CBAR"
