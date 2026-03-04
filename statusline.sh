#!/bin/bash
POMO="/tmp/pomo.status"

context() {
  cat | jq -r '.context_window.used_percentage // 0 | floor'
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
  printf '█%.0s' $(seq 1 $n)
  printf '░%.0s' $(seq 1 $((10 - n)))
}

bar() {
  local pct=$1 icon=$2 clr
  clr=$(color "$pct" "$3" "$4" "$5")
  printf "%s ${clr}%s\033[0m" "$icon" "$(blocks "$pct")"
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

PCT=$(context)
CBAR=$(bar "$PCT" "🧠" 50 70)
PBAR=$(pomo) && printf "%s %s\n" "$CBAR" "$PBAR" || printf "%s\n" "$CBAR"
