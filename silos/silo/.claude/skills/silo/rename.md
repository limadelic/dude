# Rename

## What

A rename keeps the session id and its record. Only the name changes, in the files and in the session.

## How

- A name uses letters, digits, dots and dashes. Never `@`, SendMessage reads it as a team. Never `:`, it is plugin scope
- Agent file: `mv` to `<new>.md`, set frontmatter `name:`, `git mv` inside a repo
- Every live `agents` folder with a copy, skip `.agents` archives and worktrees
- Roster rows in every CLAUDE.md and CLAUDE.local.md that name it
- Files that call it by name, grep the old word
- Session: back up, then edit `~/.claude/jobs/<short>/state.json`, `name`, `template`, `intent`, and the values after `--name` and `--agent` in `respawnFlags`
- Transcript: append `custom-title`, `agent-name` and `agent-setting` lines with the new name, never edit old lines
- A live session keeps the edit, read `state.json` twice 20s apart to be sure
- Never drive `claude agents` by script, it renamed the wrong row and started a twin
- Verify: one row, the old id, the new name, and SendMessage by the new name gets an answer
- The twins check groups by exact name, it does not see an old-name row and a new-name row as twins
