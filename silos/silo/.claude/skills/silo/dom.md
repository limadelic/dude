# Dom

## What

A dom is one domain of the human's work: one folder, its own silos. Doms: dude, elita, ghost, ops, pf, quijote, rec, sancho.

## How

- A dom stays at its real path, never move it to get a short name
- A dom has two links: `~/<dom>` to the real path, and the label `~/<dom><emoji>` to `~/<dom>`, like `~/dom/dude🎳 → ~/dude`
- ghost, elita and dude use the label in `~/dom`: `~/dom/ghost👻`, `~/dom/elita🐶`, `~/dom/dude🎳`
- dude keeps `~/dude` as its folder link
- A dom silo's state.json cwd and originCwd are the label `~/<dom><emoji>`, agent view shows it
- The label in state.json cwd is the silo's dom, the roster follows it, never move a silo to match the roster
- Only the cwd knows the label, every flag, add-dir and ref uses `~/<dom>`
- A nested dom inherits every parent CLAUDE.md, a move cuts that off
- Shared rules come by an explicit `@` import, knowledge comes by a message to the dom's silo
- `~/.claude` is the real folder, `~/dude` is a symlink to it
