---
name: await
description: Use this skill when you need to await something to complete. Trigger when asked to wait, watch, monitor, or check on running processes.
---

# Await Background Tasks

## Scripts

- `wait-until.sh <predicate> [interval]` - loop until predicate is true (exit 0)
- `wait-while.sh <predicate> [interval]` - loop while predicate is true, stop when false

Predicate = any command that exits 0 for true, non-zero for false (e.g. `grep -q`, `test`, `[[ ]]`)

Default interval: 30s

## Usage

Run with `run_in_background: true`. Wait for completion notification.

Compose the check command yourself based on the situation.

## Key Principle

Never block. Run in background, do other work, act when it finishes.

Don't check progress repeatedly. Wait for the task to complete. Do not use sleep.

One monitor per task. 3 things = 3 background tasks.
