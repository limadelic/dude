# Dup

## What

Two sessions with one identity race each other on the same job. Find them by session id, remove the junior, touch nothing else.

## How

- Any door that makes a new session with a silo's identity makes a twin: a spawn, an unprobed launch, a resume with a prompt or a flag
- A sighting resolves to session ids first, `bin/twins` reads `claude agents --all --json`, live and done rows
- A session with a color is mike's, never touch it
- Act on session ids only, never on a name or a menu row
- Keep the colored or elder one, `claude stop` then `claude rm` the junior by id
- Snapshot before and after, the diff is the junior id only, if not, stop and tell mike
- Done is one row in mike's menu, not a clean json
- Watch: Monitor on `bin/twins` every 60s, report, stop nothing without mike

## Drill

- Learn on a fake first, from `/tmp/fakesilo` launch twice: `claude --bg --name fakesilo "Fake test silo. Do nothing."`
- `bin/twins` flags the pair and nothing else, dedup it, then stop and rm the elder, the snapshot matches the one before
