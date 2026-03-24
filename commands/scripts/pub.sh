#!/bin/bash
set -e

CWD="$1"
ARG="$2"

# resolve name
NAME="${ARG:-$(basename "$CWD")}"

CLAUDE_DIR="$CWD"
[ -d "$CWD/.claude" ] && CLAUDE_DIR="$CWD/.claude"

DUDES_DIR="$CLAUDE_DIR/dudes"
mkdir -p "$DUDES_DIR"

# inbox
[ -f "$DUDES_DIR/inbox.json" ] || echo '[]' > "$DUDES_DIR/inbox.json"

# status.json - merge name into existing or create
if [ -f "$DUDES_DIR/status.json" ]; then
  tmp=$(mktemp)
  jq --arg n "$NAME" '.name = $n' "$DUDES_DIR/status.json" > "$tmp" && mv "$tmp" "$DUDES_DIR/status.json"
else
  echo "{\"name\":\"$NAME\"}" > "$DUDES_DIR/status.json"
fi

# symlink
mkdir -p "$HOME/.claude/dudes"
ln -sfn "$CLAUDE_DIR/" "$HOME/.claude/dudes/$NAME"

echo "$NAME"
