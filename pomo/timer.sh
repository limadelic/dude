#!/bin/bash
# Pomo timer - runs for specified minutes, auto-chains to next phase
MINUTES="${1:-25}"
LABEL="${2:-work}"
ROUND="${3:-1}"
STATUS_FILE="/tmp/pomo.status"

SECONDS_TOTAL=$(echo "$MINUTES * 60" | bc | cut -d. -f1)
END_TIME=$(($(date +%s) + SECONDS_TOTAL))

echo "$LABEL|$END_TIME|$ROUND" > "$STATUS_FILE"
echo "$(date +%H:%M:%S) pomo started: $MINUTES min ($LABEL)"

sleep "$SECONDS_TOTAL"

echo "$(date +%H:%M:%S) pomo done: $LABEL"
echo "transitioning|0|$ROUND" > "$STATUS_FILE"
afplay ~/.claude/skills/pomo/ding.mp3 &

POMO_MSGS=("NICE WORK 💪" "CRUSHED IT 🔥" "25 DOWN 🎯" "SOLID FOCUS 🧠" "YOU SHOWED UP ⭐" "LOCKED IN 🔒" "THAT'S HOW 👊" "DEEP WORK 🌊" "MOMENTUM 📈" "RESPECT ✊")
BREAK_MSGS=("RECHARGED 🔋" "BACK AT IT 🚀" "FRESH EYES 👀" "LET'S GO 💨" "ROUND 2 🥊" "RESET COMPLETE 🔄" "BATTERIES FULL ⚡" "STRETCH DONE 🧘" "HYDRATED 💧" "READY 🎬")

TITLE="🍅  POMO"
if [[ "$LABEL" == *break* ]]; then
  BODY="         ${BREAK_MSGS[$((RANDOM % 10))]}"
else
  BODY="         ${POMO_MSGS[$((RANDOM % 10))]}"
fi

osascript -e "display dialog \"$BODY\" with title \"$TITLE\" buttons {\"OK\"} default button \"OK\" with icon POSIX file \"$HOME/.claude/skills/pomo/tomato.icns\""

# Auto-chain to next phase
if [[ "$LABEL" == "work" ]]; then
  if [ "$ROUND" -ge 4 ]; then
    exec "$0" 15 "long break" 1
  else
    exec "$0" 5 break "$ROUND"
  fi
elif [[ "$LABEL" == "break" ]]; then
  exec "$0" 25 work $((ROUND + 1))
elif [[ "$LABEL" == "long break" ]]; then
  exec "$0" 25 work 1
fi
