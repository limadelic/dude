# SRP Refactor: Dude as Facade

## Why
Dude.rb is 200+ lines mixing messaging, publishing, process tracking, and routing. Extract into domain objects using DDD ubiquitous language.

## Who does what

### Dudes::Pub (new: `lib/dudes/pub.rb`)
Owns the publishing lifecycle — registering/tearing down a dude in the global registry.
- `pub(target, name)` — claude_dir, mkdir, init_inbox, write_status, create_symlink
- `unpub(target)` — remove_dudes, kill_watchers
- Private: claude_dir, init_inbox, write_status, load_existing, create_symlink, global_dir_exists?, remove_dudes, kill_watchers, pgrep_all, kill_process

### Dudes::Inbox (enhance: `lib/dudes/inbox.rb`)
Already has file ops. Add message construction + routing-aware methods:
- `tell(path, text)` — builds `{text, status: new}`, appends
- `ask(path, from, text)` — builds `{from, text, status: new}`, appends
- `watch(path)` — first_new + mark_wip (moved from Dude)
- `finish(path, from_path: nil, reply: nil)` — reply + dequeue_wip (moved from Dude)

### Dudes (enhance: `lib/dudes.rb`)
Already does discovery + PID tracking. Add:
- `resolve_inbox(name)` — symlink lookup → inbox path (routing)
- `read_self_name(dude_dir)` — read status.json name
- Process tracking: `is_current?(pid)`, `is_abiding?(pid, dude_dir, target)`, `pids_for_target(target)`
- Private: parent_pid, shell_parent_pid, has_ancestor_pid?, matches_abide_task?

### Dudes::Dude (slim: `lib/dudes/dude.rb`)
Thin facade — delegates everything:
- `tell(name, text)` → resolves inbox via Dudes, calls Inbox.tell
- `ask(name, text)` → resolves inbox via Dudes, calls Inbox.ask
- `pub(icon)` → Pub.pub
- `unpub` → Pub.unpub
- `watch` → Inbox.watch
- `finish(from:, reply:)` → Inbox.finish
- `is_current?` → Dudes.is_current?(pid)
- `is_abiding?` → Dudes.is_abiding?(pid, dude_dir, target)
- Keeps: initialize, to_h, messages, context

## Files
- `lib/dudes/pub.rb` — new
- `lib/dudes/inbox.rb` — enhance with tell/ask/watch/finish
- `lib/dudes.rb` — add routing + process tracking
- `lib/dudes/dude.rb` — slim to facade
- Specs follow same pattern

## Verify
- `bob test` — all specs pass
- CLI unchanged — same public API on Dude
