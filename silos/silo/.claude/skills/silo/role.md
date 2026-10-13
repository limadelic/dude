# Role

## What

One role, like kent or arana, runs in many doms. The general part is written once, each dom adds only its own config.

## How

- General part `~/dude/silos/<role>/` holds `CLAUDE.md` (the role identity and general vibe, any dom), `.claude/skills/<role>/` (how the role works) and `.claude/agents/<role>.md` (its haiku sub).
- Dom config `<dom>/.claude/silos/<role>/CLAUDE.md` holds the dom facts only, never the identity or the general how.
- Launch: cwd `~/<dom>`, `--add-dir ~/dude/silos/<role>` and `--add-dir ~/<dom>/.claude/silos/<role>`, no `--agent`
- A new dom gets the role by a new dom config, the general part does not change
