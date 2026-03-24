#!/bin/bash
set -e

NAME="$1"
shift
TEXT="$*"

INBOX="$HOME/.claude/dudes/$NAME/dudes/inbox.json"
[ -f "$INBOX" ] || { echo "dude '$NAME' not found"; exit 1; }

SELF=$(jq -r '.name' "$PWD/dudes/status.json")

cat <<< "$(jq --arg from "$SELF" --arg text "$TEXT" '. += [{"from": $from, "text": $text, "status": "new"}]' "$INBOX")" > "$INBOX"
echo "ask → $NAME"
