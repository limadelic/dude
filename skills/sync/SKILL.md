---
name: sync
description: Sync ~/.claude/ to dude repo. Use when session starts or user asks to watch/sync root.
---

# Sync

## What

Watches `~/.claude/` for changes and propagates them to `~/dev/self/dude/` via branches and PRs.

## Watched Dirs

`plans`, `skills`, `commands`, `subagents`

## How

1. Start a background watcher with await skill (`run_in_background: true`):
```bash
~/.claude/skills/await/wait-until.sh \
  'for dir in plans skills commands subagents; do \
     [ -d ~/.claude/$dir ] || continue; \
     mkdir -p ~/dev/self/dude/$dir; \
     diff -rq ~/.claude/$dir/ ~/dev/self/dude/$dir/ 2>&1 | grep -q . && exit 0; \
   done; \
   exit 1' \
  15
```

2. When the watcher fires:
   - `diff -rq` the watched dirs to see what changed
   - Review open branches and PRs in dude repo:
     ```bash
     gh pr list -R UKGEPIC/dude --state open --json headRefName,title,number
     git -C ~/dev/self/dude branch -r
     ```
   - If the change fits an existing open PR/branch, checkout that branch and commit there
   - If unrelated, create a new branch from `origin/main` named after the change
   - Copy changed files, stage, commit with a descriptive message
   - Push and use `/alley-pr` to create the PR
   - Restart the watcher (step 1)

3. To stop: use TaskStop on the background task.
