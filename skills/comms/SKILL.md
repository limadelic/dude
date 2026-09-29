---
name: comms
description: How to talk to agents in la mancha. Live sessions get SendMessage, work gets a subagent, other nodes get azor.
---

# Comms

Pick the channel by who the target is.

| Target | Channel |
|--------|---------|
| Silo alive on this node (spud, molly, sonos, azor) | `SendMessage` to `name [ref]` from `ListAgents` |
| Silo dead on this node | Start it per the silo skill, never spawn a twin subagent |
| Work to do (read, edit, run) | `Agent` subagent, `run_in_background: true`, haiku by default |
| Anything on sancho | `Agent` subagent type `sancho` |
| A session on another node | azor: `from=<me> azor <session>@<node> <text>` |

## Rules

- `ListAgents` first when a silo is the target. A row means alive, message it.
- A silo request is a message, not a spawn. Spawning `Agent` with a silo type creates a twin that races the real one.
- Replies from a live session arrive as `<cross-session-message from="...">`. Reply with that `from` as `to`.
- Azor only crosses nodes. Same node, no azor.
- One ask per message, with the path, the destination, and where to reply.
