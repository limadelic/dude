# Dom

## What

A dom is one domain of mike's work: one folder, its own silos. Doms: dude, quijote, sancho, elita, rec, pf.

## How

- A dom stays at its real path, never move it to get a short name
- `~/<dom>` is a symlink to the real path, a short name for mike
- A session cwd shows the real path, the symlink never changes it
- A nested dom inherits every parent CLAUDE.md, a move cuts that off
- Shared rules come by an explicit `@` import, knowledge comes by a message to the dom's silo
- `~/.claude` is the real folder, `~/dude` is a symlink to it
