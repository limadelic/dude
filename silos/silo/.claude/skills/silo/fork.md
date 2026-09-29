# Fork

## What

A name `<silo> ⑂ <n>` is a fork of that silo. It runs on the silo's agent file and skills, it has no files of its own, it is not a twin of the silo.

## How

- Create: silo never makes a fork, a fork comes from its parent session
- Wake: same as wake.md, by full session id, no prompt, no other flag
- Dup: two rows with the same fork name are twins, dup.md applies, a fork and its silo are not twins
- Rename: session only, `name` and the `--name` value in `state.json`, append `custom-title` and `agent-name` lines, no agent file, no roster, no grep
- Name: `<silo> ⑂ <n>`, the silo part is the silo's current name
- Count: group the rows by the silo part of the name
