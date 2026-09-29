# Wake

## What

An agent asks silo to wake a silo. Silo wakes it with its record and no twin, then hands it to the asker. Never wake a silo nobody asked for.

## How

- Resolve the name to a session id, `claude agents --all --json`, one row per name
- Alive: do not resume, `SendMessage` it to talk to the asker
- Dead: from its home, `claude --bg --resume <full session id>`, no prompt, no other flag
- Dead with a color: it is mike's, do not resume it, tell mike
- Pass: `ListAgents` shows one row, same session id, `bin/twins` is empty
- Then `SendMessage` the silo: who asked, the job, talk to the asker
- Last, `SendMessage` the asker: the listing names that are live
