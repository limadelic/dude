---
description: Register this session as a pub dude
argument-hint: [name]
---

Register the current session as a pub dude.

- Resolve name: use `$ARGUMENTS` if provided, otherwise basename of cwd
- Create `{cwd}/.claude/dudes/inbox.json` with `[]` if it doesn't exist (create dirs as needed)
- Write `name` into `{cwd}/.claude/dudes/status.json` (merge with existing keys if file exists)
- Create symlink `~/.claude/dudes/{name}` pointing to `{cwd}/.claude/`
- Run `/abide` to start watching the inbox
