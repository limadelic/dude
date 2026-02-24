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

   **Open PR exists → add to it**
   - Checkout that branch
   - Sync changed files
   - Commit and push
   - Restart watcher

   **No open PR → new branch**
   - Create branch from `origin/main`. Name: `<type>-<name>` (type: `skill|agent|cmd|plan|rules`, name: max 3 words, no action verbs)
   - Sync changed files, commit, push
   - Run `/alley-pr` — do NOT wait for merge
   - Restart watcher immediately

   NEVER merge branches locally.

3. To stop: use TaskStop on the background task.
