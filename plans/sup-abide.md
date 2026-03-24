# sup-abide — Abide Health Supervision

## Goal
Statusline detects dead abide. Display-only — you see `ˣ` (red), you fix it.

## Watcher not running ✅

### How it works
1. `/abide` writes watcher PID to `status.json` via pgrep after await starts
2. Statusline reads `abide_pid` from `status.json`, checks `Process.kill(0, pid)`
3. Own dude: pgrep fallback if PID missing/dead — finds & writes PID
4. Other dudes: rely on their `status.json` only
5. No PID = dead, dead PID = dead → show red `ˣ`

## WIP without a todo

### How it works
1. Statusline reads `inbox.json` — any message with `status: "wip"`?
2. Find active session UUID: most recent `.jsonl` in `~/.claude/projects/<encoded-cwd>/`
   - Each dude has different cwd → different project dir → right session
3. Read tasks from `~/.claude/tasks/<uuid>/*.json`
4. Look for task with subject starting with `"Abide"` matching the wip message
5. Wip message + no matching task = stuck = red `ˣ`

### Changes
- **statusline.rb**: new method to find active session tasks, check wip vs todos
- **tests**: wip + no task = dead, wip + matching task = alive, no wip = alive
