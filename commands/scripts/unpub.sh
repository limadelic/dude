#!/bin/bash

DUDES_DIR="$HOME/.claude/dudes"

if [ -d "$DUDES_DIR" ]; then
  for link in "$DUDES_DIR"/*; do
    [ -L "$link" ] || continue
    target=$(readlink "$link")
    rm -rf "$target/dudes"
  done
  rm -rf "$DUDES_DIR"
fi

pkill -f "abide/watch.sh"

echo "clean"
