---
name: pomo
description: Pomodoro timer for focus sessions. Use when user feels overwhelmed, needs to focus, or asks for a pomodoro/timer.
---

# Pomo

Fire and forget. ONE command. Then leave it alone.

## Start

```bash
nohup ~/.claude/skills/pomo/timer.sh 25 work 1 > /tmp/pomo.log 2>&1 & disown
```

That's it. Say "pomo started" and move on.

## DO NOT

- DO NOT spawn an agent to watch pomo
- DO NOT poll, tail, or re-check whether it is alive
- DO NOT restart it because you are unsure it worked

`timer.sh` auto-chains every phase itself via `exec` and survives independently of
this session. There is nothing to supervise. If the command returned, it is running.

## Silent Mode

Add `silent` as 4th parameter to disable sound (for meetings):

```bash
nohup ~/.claude/skills/pomo/timer.sh 25 work 1 silent > /tmp/pomo.log 2>&1 & disown
```

Still shows visual dialog, just no ding sound.

## Cycle (auto)

- 25 min work
- 5 min break
- repeat 4x then 15 min long break
- loops forever until stopped
- auto-pauses during quiet hours (lunch 12-1, after 4:20pm)

## Status

Only when the user asks:

```bash
cat /tmp/pomo.status    # label|end_epoch|round
```

## Stop

```bash
pkill -f timer.sh; rm -f /tmp/pomo.status
```
