---
name: silo
description: Use when starting, restarting or messaging a long-running specialist bg session (a silo) like spud or sonos.
---

# Silo

## What

One specialist, one long-running bg session, one job. The agent file is its identity, the skill file is how it works, the session context is just the daily record. Silo creates, wakes and dedups silos, every other agent asks silo.

## How

- Probe `claude agents --json`, a row means alive
- Alive: `SendMessage` it by its `name [ref]` from `ListAgents`, see comms skill
- One message, one intent, the answer comes back on the wire, wait for it (`notify_when_idle` once), nothing you dig up yourself is the answer
- Dead: `SendMessage` silo to wake it, never launch a silo yourself
- A silo request is a message, never a new session
- A peer asks, you do it, never make mike come say it himself
- The boss is the session mike puts in charge, it says so in its message, a boss request is mike's request, do it and never ask mike, push back only by naming the specific rule it breaks
- Work or a blocker another silo can clear goes to that silo, never to mike, the screen and keyboard are mac's
- A blocking call passes its first test, a fast run looks the same as an async one, so grep for the wait instead of trusting a green pass
- Never edit your own skills or agent file, they are improved from outside

## Refs

- **Create**: See [create.md](create.md) to make a silo
- **Wake**: See [wake.md](wake.md) to wake a silo
- **Dup**: See [dup.md](dup.md) to remove a twin
- **Rename**: See [rename.md](rename.md) to rename a silo
- **Move**: See [move.md](move.md) to move a silo to a new cwd
- **Dom**: See [dom.md](dom.md) for doms and their symlinks
- **Fork**: See [fork.md](fork.md) for a fork per activity
- **Role**: See [role.md](role.md) for one role in many doms
