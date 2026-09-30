# Create

## What

Silo makes every new silo. One identity, one session.

## How

- Identity in the home's `CLAUDE.md`, or `.claude/CLAUDE.md` when the repo tracks one, ~20 lines, dispatch don't do
- Write its sub `<home>/.claude/agents/<name>.md`: haiku, `skills: [<name>]`, body says do the one task and return evidence only. Its CLAUDE.md says every read, edit and run goes to that sub
- No agent file, `--agent` does not find one in an added dir
- Its own skill `<home>/.claude/skills/<silo>/SKILL.md` for how it works, shared procedure skills beside it, `silo` always among them
- Roster row in the dom's CLAUDE.md
- State that must outlive a restart, a watch list or a seen set, is a data file in `skills/<silo>/`, never /tmp, never inside the instructions
- Scripts go in `skills/<silo>/bin/`
- Probe `claude agents --all --json` first, a row with the name means no launch
- From the dom root: `claude --bg --name <silo> --add-dir <home> --settings '{"env":{"CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD":"1"}}' --dangerously-skip-permissions "<check prompt>"`
- Without the env the home CLAUDE.md does not load, the bg daemon has no shell env
- Without `--dangerously-skip-permissions` it can not read or run
- Verify: it states its job, it sees its skill, one row, `bin/twins` is empty, then leave it alone