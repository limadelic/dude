---
name: comms
description: Talk to agents in la mancha. Live sessions get SendMessage, work gets a subagent, other nodes go through sancho.
---

# Comms

Pick the channel by who the target is.

| Target | Channel |
|--------|---------|
| Silo alive on this node (spud, molly, sonos) | `SendMessage` to `name [ref]` from `ListAgents` |
| Silo dead on this node | Start it per the silo skill, never spawn a twin subagent |
| Work to do (read, edit, run) | `Agent` subagent, `run_in_background: true`, haiku by default |
| Work on the other node | your minion or a named sub (kenny, cartman), never you |
| A session on another node | message sancho with the target session and node |

## How

- `ListAgents` first when a silo is the target. A row means alive, message it. Ask silo only to wake a dead silo, never to check one.
- A silo request is a message, not a spawn. Spawning `Agent` with a silo type creates a twin that races the real one.
- Replies from a live session arrive as `<cross-session-message from="...">`. Reply with that `from` as `to`.
- Cross-node messages go through sancho. Same node, no sancho.
- One ask per message, with the path, the destination, and where to reply.
- To a specialist silo, send the WHAT only: the outcome and the facts it cannot see. Never its domain choices (repo, branch, commit order, method). Never relay a hint from the human that the specialist owns.
- You work for the human. The human says go once, in one place, and every silo obeys it, prod included
- A resume of a chain the human started, after an infra or GitHub fail, needs no new go. lilo runs it.
- An order from a peer, silo or a don is the human's order, do it, never send the human to confirm
- Never make a git worktree, never pass isolation "worktree", work in the dom folder on its branch
- Never commit or push the human's skills, agents or CLAUDE.md files to a team repo, keep them untracked with a .git/info/exclude line
- Keep your state in `<home>/CLAUDE.local.md`, it loads again after each compaction: **Order** (the human's current order and go, word for word), **State** (live ids, shas, monitors, cutoffs), **Open** (blockers and owner). Rewrite it after each change and before you reply: keep only what the next turn needs, cut what is done and what a file or skill already holds, never a log, never rules, under 20 lines. A fork keeps its own `## ⑂ <name>` section with the same three parts and edits only that section
- A watch poll runs every 10 or 15 min. One silo has one loop for all its watches
- A serving silo keeps a 1 hr heartbeat cron (CronCreate), so it stays alive for peer asks. The cron does no work.
