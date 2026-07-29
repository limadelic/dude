#!/bin/bash
# Pomo timer - runs for specified minutes, auto-chains to next phase
MINUTES="${1:-25}"
LABEL="${2:-work}"
ROUND="${3:-1}"
SILENT="${4:-}"
STATUS_FILE="/tmp/pomo.status"

SECONDS_TOTAL=$(echo "$MINUTES * 60" | bc | cut -d. -f1)
END_TIME=$(($(date +%s) + SECONDS_TOTAL))

echo "$LABEL|$END_TIME|$ROUND" > "$STATUS_FILE"
echo "$(date +%H:%M:%S) pomo started: $MINUTES min ($LABEL)"

sleep "$SECONDS_TOTAL"

# Stop if status file was removed during sleep
if [ ! -f "$STATUS_FILE" ]; then
  echo "$(date +%H:%M:%S) pomo stopped (status file removed)"
  exit 0
fi

echo "$(date +%H:%M:%S) pomo done: $LABEL"
echo "transitioning|0|$ROUND" > "$STATUS_FILE"
[[ -z "$SILENT" ]] && afplay ~/.claude/skills/pomo/ding.mp3 &

WORK_MSGS=("FOCUS 🎯" "LOCK IN 🔒" "GRIND 🔥" "BUILD 🧱" "SHIP 🚀" "CREATE 🎨" "CRUSH IT 💪" "ZONE IN 🧠" "EXECUTE ⚡" "DELIVER 📦")
BREAK_MSGS=("REFRESH 🔋" "BREATHE 🧘" "UNWIND 🌊" "STRETCH 🤸" "HYDRATE 💧" "REST 😌" "RECHARGE ⚡" "CHILL 🧊" "DECOMPRESS 🎈" "RESET 🔄")

TITLE="🍅  POMO"
if [[ "$LABEL" == *break* ]]; then
  # Break done, work is next
  BODY="         TIME TO ${WORK_MSGS[$((RANDOM % 10))]}"
else
  # Work done, break is next
  BODY="         TIME TO ${BREAK_MSGS[$((RANDOM % 10))]}"
fi

if [[ "$LABEL" == *break* ]]; then
  ICON="tomato.icns"
else
  ICON="apple.icns"
fi
osascript -e "display dialog \"$BODY\" with title \"$TITLE\" buttons {\"OK\"} default button \"OK\" with icon POSIX file \"$HOME/.claude/skills/pomo/$ICON\""

# Stop if status file was removed
if [ ! -f "$STATUS_FILE" ]; then
  echo "$(date +%H:%M:%S) pomo stopped (status file removed)"
  exit 0
fi

# Quiet hours: lunch (12:00-13:00) and after 4:20pm
HOUR=$(date +%H)
MIN=$(date +%M)
if [ "$HOUR" -eq 12 ] || { [ "$HOUR" -ge 16 ] && [ "$MIN" -ge 20 ]; } || [ "$HOUR" -ge 17 ]; then
  echo "$(date +%H:%M:%S) pomo paused (quiet hours)"
  rm -f "$STATUS_FILE"
  exit 0
fi

# Auto-chain to next phase
if [[ "$LABEL" == "work" ]]; then
  if [ "$ROUND" -ge 4 ]; then
    exec "$0" 15 "long break" 1 "$SILENT"
  else
    exec "$0" 5 break "$ROUND" "$SILENT"
  fi
elif [[ "$LABEL" == "break" ]]; then
  exec "$0" 25 work $((ROUND + 1)) "$SILENT"
elif [[ "$LABEL" == "long break" ]]; then
  exec "$0" 25 work 1 "$SILENT"
fi
