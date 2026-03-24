#!/bin/bash
DIR="$PWD"
[ -d "$PWD/.claude" ] && DIR="$PWD/.claude"
INBOX="$DIR/dudes/inbox.json"
STATUS="$DIR/dudes/status.json"

[ ! -f "$INBOX" ] && echo "the dude abides" && exit 0

cat <<< "$(jq --argjson pid "$$" '.watcher_pid = $pid' "$STATUS")" > "$STATUS"

watch() {
  ~/.claude/skills/await/wait-until.sh "jq -e 'length > 0 and .[0].status == \"new\"' $INBOX"
}

wip() {
  cat <<< "$(jq '.[0].status = "wip"' "$INBOX")" > "$INBOX"
}

msg() {
  jq -c '.[0]' "$INBOX"
}

watch && wip && msg
