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

1. Start a background watcher with await skill (`run_in_background: true`). Uses `wait-while` + subshell so `exit` doesn't kill the parent:
```bash
~/.claude/skills/await/wait-while.sh \
  '(for dir in plans skills commands subagents; do \
     [ -d ~/.claude/$dir ] || continue; \
     mkdir -p ~/dev/self/dude/$dir; \
     diff -rq --exclude=.DS_Store ~/.claude/$dir/ ~/dev/self/dude/$dir/ 2>&1 | grep -q . && exit 1; \
   done; exit 0)' \
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
   - If multiple unrelated things changed, split into separate branches — one per logical change (e.g. one skill = one branch, related commands = one branch). Never bundle unrelated changes.
   - Branch per change from `origin/main`. Name format: `<type>-<name>` where type is `skill|agent|cmd|plan|rules` and name is max 3 words describing the spirit of the change (e.g. `skill-sync-watcher`, `cmd-badbunny`, `plan-enigma`). No action verbs.
   - Copy changed files, stage, commit with a descriptive message
   - Push and use `/alley-pr` to create the PR (skip if adding to existing PR)
   - Repeat for each logical change before restarting the watcher
   - Stay on the branch — do NOT checkout main. The watcher diffs the filesystem, so the working tree must match `~/.claude/` for the diff to go quiet.
   - Restart the watcher (step 1)

3. To stop: use TaskStop on the background task.
