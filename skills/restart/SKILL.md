---
name: restart
description: Restart Claude Code. Use when config changes, hooks updated, or user asks to restart.
---

# Restart

## What

Restarts the current Claude Code session by creating a marker file and exiting.

## How

```bash
touch ./restart
```

Then `/exit`.

The yolo wrapper detects the restart file and relaunches automatically.
