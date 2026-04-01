---
name: bob
description: Run dude gem tasks (test, install) and git ops. Delegates to bob subagent.
---

# bob

Delegate to the `bob` subagent with the argument passed.

## Commands
- `test` — run specs
- `cukes` — run cucumber features
- `install` — build and install gem
- `commit "msg"` — commit with message
- `push` — push to remote
- `all "msg"` — test → install → commit → push

## Rules
- Pass ONLY the command word. Bob knows how to run them.
- NEVER add paths, flags, or implementation details — Bob has them.
- NEVER guess how commands work — you don't know, Bob does.
