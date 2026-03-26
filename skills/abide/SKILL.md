---
name: abide
description: Use to handle other Agents (dudes) requests. Triggered by a bg watcher.
---

# AWAIT TO ABIDE

- Run `dude abide` with `run_in_background: true`

# DO ABIDE

The watcher echoes the message when it arrives.
Handle it, then proceed to DONE ABIDING.

# DONE ABIDING

- If from is present, a reply is expected.
  If reply is too long, write to `plans/` instead.
  Run `dude abided "{from}" "{reply}"`
- If no from, run `dude abided`
- Watch again!