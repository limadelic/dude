---
name: sync
description: Watch ~/.claude for changes, branch, commit, push, PR. Use when session starts or user asks to sync.
---

# Sync

## What

Watches `~/.claude/` (the dude repo) for uncommitted changes. When found, branches, commits, pushes, and PRs via `/alley-pr`.

`.gitignore` controls what's tracked. No file lists.

## How

1. Start a background watcher with await skill (`run_in_background: true`):
```bash
~/.claude/skills/await/wait-until.sh \
  'cd ~/.claude && test -n "$(git status --porcelain)"' \
  15
```

2. When the watcher fires:
   - `git status --porcelain` to see what changed
   - `gh pr list -R UKGEPIC/dude --state open --json headRefName,title,number,url`

   **Open PR exists → add to it**
   - Checkout that branch
   - `git add -A && git commit` with concise message
   - `git push`
   - Restart watcher

   **No open PR → new branch**
   - Create branch from `origin/main`. Name: `<type>-<name>` (type: `skill|agent|cmd|plan|rules`, name: max 3 words, no action verbs)
   - `git add -A && git commit` with concise message, push
   - Run `/alley-pr` — do NOT wait for merge
   - Restart watcher immediately

   NEVER merge branches locally.

3. To stop: use TaskStop on the background task.
