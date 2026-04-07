---
name: sup
description: Team supervising skill. Use when creating, managing, or tearing down teams.
---

# Sup

## What
Manage agent teams — spin up with exact names, tear down cleanly.

## How

### Start a Team
1. `TeamCreate` with team name and description
2. Spawn each agent with `Agent` tool — use EXACT `name` and `subagent_type` from the skill that defines the team (e.g., 3-amigos skill has a table)
3. Always include "REPLY to me" in spawn prompt
4. Always set `run_in_background: true` and `team_name`
5. ONLY spawn the agents listed in the cast — no extras. If you need utility work (reading files, searching, etc.), use plain subagents WITHOUT `team_name`. Ask the user before adding anyone not in the cast.

### Stop a Team
1. Send `{"type": "shutdown_request"}` via `SendMessage` to each teammate
2. Wait for `shutdown_approved` responses
3. If teammates go idle without approving — they won't. Skip to step 4
4. `TeamDelete` to clean up directories (works when teammates are idle)
5. Idle processes die on their own once team files are gone

### Nuclear Option (when teammates won't stop)
1. Try `TeamDelete` first
2. If that fails (active members), manually clean up:
   - `mv ~/.claude/teams/<team-name> /tmp/`
   - `mv ~/.claude/tasks/<team-name> /tmp/`
3. Orphaned processes die on their own once team files are gone
