# Create

## What

Silo makes every new silo. One identity, one session.

## How

- Agent file in the home's `.claude/agents/<silo>.md`, ~30 lines, dispatch don't do
- Its own skill `skills/<silo>/SKILL.md` for how it works, shared procedure skills beside it, `silo` always among them
- Roster row in that home's CLAUDE.md
- State that must outlive a restart, a watch list or a seen set, is a data file in `skills/<silo>/`, never /tmp, never inside the instructions
- Scripts go in `skills/<silo>/bin/`
- Files keep the word, the glyph goes in frontmatter as `icon:`, launch with it as `--name`
- Probe `claude agents --all --json` first, a row with the name means no launch
- From its home: `claude --bg --name <silo> --agent <silo> --dangerously-skip-permissions "<job prompt>"`
- Without `--dangerously-skip-permissions` it can not read or run
- Verify one row, then leave it alone
