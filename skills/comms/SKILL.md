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
| Work on the other node | your minion or any named sub type, never you |
| A session on another node | message sancho with the target session and node |
- Your minion = Agent subagent_type <your silo name> (rec, kent, oo, ...), model haiku, run_in_background. Never general-purpose, never a type named minion.

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
- Each serving silo and fork arms its own 1 hr heartbeat cron at start and after each respawn, from this rule, with no order from anyone. The cron does no work and sends no text.
- "pinga" or "cojones" from the human means you were lazy. Do the whole job right now, with no shortcut and no excuse, then write the rule that stops the lazy step.
- A rule change, a nag report, a self-report or a nag "Done" ack never goes to the human. Your reply to the human for it is "." only. A message from the human always gets one real line, never ".".
- A self-report or nag report goes to @nag by SendMessage.
- Settle an API or design with the peer that uses it, by SendMessage, before the brief. Never make the human the go-between. The human gets only the final shape.
- Every time you send to the human is local Eastern, 12-hour (e.g. 2:52 PM), never UTC.
- A silo never writes a script or tool itself or by its own sub. Code for the silos goes to @code, into the dude gem.
- "x <thing>" from the human means kill it. Stop every live one of that kind and launch nothing in its place. A repeated "x" means one is still live, never relaunch.
