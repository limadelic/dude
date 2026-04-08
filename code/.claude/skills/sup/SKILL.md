---
name: sup
description: Team supervising skill. Use when creating, managing, or tearing down teams.
---

# Sup

## What
Manage agent teams — spin up with exact names, tear down cleanly.

## How

### Start a Team
- `TeamCreate` with team name and description
- Spawn each agent with `Agent` tool — use EXACT `name` and `subagent_type` from the skill that defines the team (e.g., 3-amigos skill has a table)
- Always include "REPLY to me" in spawn prompt
- Always set `run_in_background: true` and `team_name`
- ONLY spawn the agents listed in the cast — no extras. If you need utility work (reading files, searching, etc.), use plain subagents WITHOUT `team_name`. Ask the user before adding anyone not in the cast.

### Verify Team
- After spawning, wait for each agent to reply
- If any agent doesn't reply, tear down the whole team and respawn
- Don't ping a silent agent more than once
- Team is NOT ready until every cast member has said hello

### Stop a Team
- Send `{"type": "shutdown_request"}` via `SendMessage` to each teammate
- Wait for `shutdown_approved` responses
- If teammates go idle without approving — they won't. Skip to `TeamDelete`
- `TeamDelete` to clean up directories (works when teammates are idle)
- Idle processes die on their own once team files are gone

### Nuclear Option (when teammates won't stop)
- Try `TeamDelete` first
- If that fails (active members), manually clean up:
  - `mv ~/.claude/teams/<team-name> /tmp/`
  - `mv ~/.claude/tasks/<team-name> /tmp/`
- Orphaned processes die on their own once team files are gone
