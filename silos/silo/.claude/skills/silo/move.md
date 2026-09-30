# Move

## What

Move a silo to a new cwd, same session id, no twin.

## How

- Resolve the name to one session id, `claude agents --all --json`
- With a color: it is mike's, do not move it, tell mike
- Back up `~/.claude/jobs/<id8>/state.json` to /tmp
- `mkdir -p ~/.claude/projects/<new cwd encoded>`, every `/` and `.` becomes `-`
- `mv` the `<id>.jsonl` and the `<id>` dir there, then `ln -s` each back at its old path
- In state.json set `cwd` and `originCwd` to the new cwd, the new cwd is the `~/<dom>` symlink path, `linkScanPath` to the new jsonl
- Alive: kill its live process, then if its row is dead after the kill, wake it per [wake.md](wake.md)
- Dead: wake it per [wake.md](wake.md)
- Pass: state.json `cwd` is the new cwd, the silo answers a ping
