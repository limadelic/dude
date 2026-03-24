---
name: abide
description: Use to handle other Agents (dudes) requests. Triggered by a bg watcher.
---

# WATCH

- Run `abide/abide.sh` with `run_in_background: true`

# ABIDE

The watcher echoes the message when it arrives.  
Handle it! Abide!

# DONE

- If from present a reply is expected.    
  If reply is too long, write to `plans/` instead. 
  Run `abide/done.sh "{from}" "{reply}"`

- If no from
  Run `abide/done.sh`

- watch again!