---
name: sync
description: Sync ~/.claude/ to dude repo. Use when session starts or user asks to watch/sync root.
---

# Sync

## What

Watches `~/.claude/` for changes and propagates them to `~/dev/self/dude/` via one branch at a time.

## Watched

### Dirs
`plans`, `skills`, `commands`, `subagents`

### Files
`CLAUDE.md`, `statusline.sh`, `settings.json`, `.mcp.all.json`

## How

1. Start a background watcher with await skill (`run_in_background: true`):
```bash
~/.claude/skills/await/wait-while.sh \
  '(for dir in plans skills commands subagents; do \
     [ -d ~/.claude/$dir ] || continue; \
     mkdir -p ~/dev/self/dude/$dir; \
     diff -rq --exclude=.DS_Store ~/.claude/$dir/ ~/dev/self/dude/$dir/ 2>&1 | grep -q . && exit 1; \
   done; \
   for f in CLAUDE.md statusline.sh settings.json .mcp.all.json; do \
     diff -q ~/.claude/$f ~/dev/self/dude/$f 2>&1 | grep -q . && exit 1; \
   done; \
   exit 0)' \
  15
```

2. When the watcher fires:
   - `diff -rq` to see what changed
   - `gh pr list -R UKGEPIC/dude --state open --json headRefName,title,number,url`

   **Path A: Existing open PR, change is in scope**
   - In scope = change to same files/area as current PR
   - Sync changes to current branch
   - Push
   - Restart watcher (diffs quiet on same branch)

   **Path B: No open PR**
   - Create branch from `origin/main`. Name: `<type>-<name>` (type: `skill|agent|cmd|plan|rules`, name: max 3 words, no action verbs)
   - Sync changes and push
   - Run `/alley-pr` and WAIT for full completion (PR created, approved, merged, back on main)
   - Then restart watcher

   **Path C: Existing open PR, change is out of scope**
   - Out of scope = change to different files/skills than current PR
   - STOP watcher (TaskStop)
   - Open current PR URL in browser
   - Tell user PR needs to be merged first
   - DON'T restart watcher (user restarts manually after merge)

   NEVER merge branches locally.

3. To stop: use TaskStop on the background task.
