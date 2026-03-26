# Abide Plan — Shell → Ruby Migration

## Goal
Move ALL bash plumbing (pub, unpub, tell, ask, abide, done) into the dude gem.
Commands/skills invoke `dude <subcommand>` instead of shell scripts.

## Why
- Shell scripts are fragile, hard to test, duplicating logic already in Ruby
- Ruby classes can be specced with mock FS, same pattern as existing code
- Single `dude` CLI binary already exists (Thor), just needs subcommands

## Architecture

### New CLI Subcommands (cli.rb via Thor)
- `dude pub [name]` — register this session as a pub dude
- `dude unpub` — tear down dudes dir and symlinks
- `dude tell <name> <message>` — send message (no reply expected)
- `dude ask <name> <message>` — send message with from field (reply expected)
- `dude abide` — watch inbox, mark wip, return first new message
- `dude done [from] [reply]` — dequeue wip, optionally reply

### New Ruby Classes (lib/dudes/)
- `Dudes::Pub` — mkdir dudes/, init inbox.json, write status.json, create symlink
- `Dudes::Unpub` — remove symlinks, dudes dirs, kill watchers
- `Dudes::Inbox` — read/write inbox operations (append msg, mark wip, dequeue, reply)

### Reuse Existing
- `Helpers::FS` — add mkdir, symlink, rm_symlink, rm_dir methods as needed
- `Helpers::Json` — already handles read, add write_json
- `Dudes::Home` — already reads dude links/data, reuse for tell/ask target resolution

## Steps

### 1. Dudes::Inbox (pure inbox operations)
- `append(inbox_path, message_hash)` — add message to inbox array
- `mark_wip(inbox_path)` — set first item status to "wip"
- `dequeue_wip(inbox_path)` — remove first item if wip
- `first_new(inbox_path)` — return first item with status "new"
- Spec first, mock FS

### 2. Dudes::Pub
- `register(cwd, name)` — mkdir, init inbox/status, create symlink
- Needs: FS.mkdir_p, FS.symlink (new FS methods)
- Spec first

### 3. Dudes::Unpub
- `teardown` — find symlinks, remove dudes dirs, remove symlinks
- Needs: FS.rm_dir, FS.rm_symlink (new FS methods)
- Spec first

### 4. CLI subcommands
- Wire Thor subcommands to classes
- `dude tell` → resolve target via Home, append via Inbox
- `dude ask` → same but with from field from status.json
- `dude abide` → Inbox.first_new, loops via wait-until (or Ruby polling)
- `dude done` → Inbox.dequeue_wip, optionally Inbox.append to reply target

### 5. Update commands/skills to call gem
- `tell.md` → `dude tell $ARGUMENTS`
- `ask.md` → `dude ask $ARGUMENTS`
- `pub.md` → `dude pub $ARGUMENTS`
- `unpub.md` → `dude unpub`
- `abide/SKILL.md` → `dude abide`
- `abide/done.sh` → `dude done`

### 6. Delete shell scripts
- commands/scripts/tell.sh, ask.sh, pub.sh, unpub.sh
- skills/abide/abide.sh, done.sh, todo.sh

## Decided
- ALL bash goes away, including wait-until polling
- `dude abide` does its own polling loop in Ruby (sleep + check inbox)
- `dude await` replaces wait-until.sh — generic Ruby poller for any condition
- Helpers::Wait — sleep loop with configurable interval and timeout

## Parked
- Reply envelope format
- Orphan WIP recovery
- Sub dudes (ephemeral scoped dudes)