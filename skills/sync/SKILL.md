---
name: sync
description: Automates changes to global claude configuration.
---

# Sync

Watch for changes and Push them. 
MUST not skip watch.

## Watch

Run /await `test -n "$(git -C ~/.claude status --porcelain)"`

## Push

After watch detects changes, push them following [push.md](push.md).
