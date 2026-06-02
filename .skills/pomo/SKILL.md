---
name: pomo
description: Pomodoro timer for focus sessions. Use when user feels overwhelmed, needs to focus, or asks for a pomodoro/timer.
---

# Pomo

Auto-cycling pomodoro. Start once, it handles the rest.

## Start

Two steps - BOTH required:

```bash
nohup ~/.claude/skills/pomo/timer.sh 25 work 1 > /tmp/pomo.log 2>&1 & disown
```

```bash
~/.claude/skills/pomo/resume.sh  # run_in_background: true
```

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

## Stop

Three steps - ALL required, in this order:

```bash
pkill -f "timer.sh"        # 1. kill the timer process
```

Stop the resume.sh background task (TaskStop).  # 2. stop the watcher

```bash
rm /tmp/pomo.status         # 3. remove status file
```

## Recovery

Run resume.sh with run_in_background - picks up wherever it left off.
