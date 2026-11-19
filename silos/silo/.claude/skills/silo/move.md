# Move

## What

Move a silo to a new cwd, same session id, no twin.

## How

- Resolve the name to one session id, `claude agents --all --json`
- Change only `cwd`, `originCwd` and `linkScanPath`, keep `color`, `respawnFlags` and every other field
- Copy `~/.claude/jobs/<id8>/state.json` to state.json.bak next to it
- `mkdir -p ~/.claude/projects/<new cwd encoded>`, every `/` and `.` becomes `-`
- `mv` the `<id>.jsonl` and the `<id>` dir there, then `ln -s` each back at its old path
- In state.json set `cwd` and `originCwd` to the new cwd. The new cwd is `~/<dom><emoji>/<home path under the dom root>` per [dom.md](dom.md), with the home taken from silos.json, never another silo's home. A silo that runs at the dom root and loads its home by --add-dir keeps the label as cwd. Set `linkScanPath` to the new jsonl
- Alive: no kill, no wake, the state.json change moves its agent view row
- Dead: wake it per [wake.md](wake.md)
- Pass: state.json `cwd` is the new cwd, the silo answers a ping
- A move is done only when the row has an order file in its dom group (dom.md Order) and every live row of that dom has its sessions/<pid>.json cwd on the dom label or a path under it, not the realpath. A minion checks each
- Idle = status "idle" in the row or in sessions/<pid>.json. An inFlight `session_cron` in job state.json is a standing cron, not work