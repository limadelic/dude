#!/bin/bash
set -e

NAME="$1"
shift
TEXT="$*"

TARGET=$(readlink -f "$HOME/.claude/dudes/$NAME" 2>/dev/null || echo "$HOME/.claude/dudes/$NAME")
INBOX="$TARGET/dudes/inbox.json"
[ -f "$INBOX" ] || { echo "dude '$NAME' not found"; exit 1; }

cat <<< "$(jq --arg text "$TEXT" '. += [{"text": $text, "status": "new"}]' "$INBOX")" > "$INBOX"
echo "tell → $NAME"
