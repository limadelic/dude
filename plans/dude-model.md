# Dude-Centric Model

## Core: `Dudes::Dude`

A Dude is a running session. It knows where it lives (`cwd`). It has an inbox. It can do things.

### Constructor

`Dude.new(name:, target:, ...)` — Dudes (the aggregator) loads all symlinks and creates each Dude with everything it already knows. By the time a Dude exists, it's fully identified. No discovery, no cwd sniffing.

### Verbs

| verb | what it does | current class |
|------|-------------|---------------|
| `pub(icon)` | register myself: create dirs, init inbox, write status, create symlink | Pub |
| `unpub` | tear down: remove dirs, symlink, kill watchers | Unpub |
| `tell(name, msg)` | drop a message in another dude's inbox | Tell |
| `ask(name, msg)` | tell + attach my name as return address | Ask |
| `watch` | check my own inbox, return first new msg, mark wip | Watch |
| `finish(reply=nil)` | if reply, send it back to `from`; dequeue wip from my inbox | Abided |

### Internal

- **inbox** — not a separate object. Just private methods on Dude that read/write the JSON file. `append_to(path, msg)`, `first_new`, `mark_wip`, `dequeue_wip`. The dude knows its own inbox path. For other dudes, it resolves via symlink.
- **resolve(name)** — follow symlink in global dir, return the other dude's inbox path. Private.
- **my_inbox_path** — `File.join(cwd, 'dudes', 'inbox.json')`. Private.

### What disappears

- `Dudes::Inbox` class — absorbed into Dude
- `Dudes::Ask` class — becomes `dude.ask`
- `Dudes::Tell` class — becomes `dude.tell`
- `Dudes::Watch` class — becomes `dude.watch`
- `Dudes::Abided` class — becomes `dude.finish`
- `Dudes::Pub` class — becomes `dude.pub`
- `Dudes::Unpub` class — becomes `dude.unpub`
- `resolve_inbox` duplication — one private method on Dude

### What stays separate

- `Dudes::Home` — discovers all dudes from symlinks (aggregator concern, not single dude)
- `Dudes::Health` — monitors processes (system concern)
- `Dudes::Renderer` — display (view concern)
- `Dudes::Tasks` — task detection (system concern)
- `Dudes::BackgroundTasksCli` — process listing (CLI concern)

### Current `Dudes::Dude` (display object)

Gets replaced. Right now it's a dumb struct with `icon, inbox, status, dude_dir, target, name`. The new Dude is the real thing — it can act. Home still creates Dude instances but now they're capable objects, not data bags.
