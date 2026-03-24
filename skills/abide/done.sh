#!/bin/bash
FROM="$1"
REPLY="$2"

DIR="$PWD"
[ -d "$PWD/.claude" ] && DIR="$PWD/.claude"
INBOX="$DIR/dudes/inbox.json"

# Reply if it was an ask (from + reply both present)
if [ -n "$FROM" ] && [ -n "$REPLY" ]; then
  TARGET=$(readlink -f ~/.claude/dudes/"$FROM" 2>/dev/null)
  TARGET_INBOX="$TARGET/dudes/inbox.json"
  cat <<< "$(jq --arg text "$REPLY" '. += [{"text": $text, "status": "new"}]' "$TARGET_INBOX")" > "$TARGET_INBOX"
fi

# Remove first message if wip
cat <<< "$(jq 'if .[0].status == "wip" then .[1:] else . end' "$INBOX")" > "$INBOX"
