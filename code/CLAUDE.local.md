# Current Task: Test 3 Amigos Team

## Context
Read `~/.claude/plans/ddd_vibes_friday.md` for the full DDD Vibes Friday plan.

## What You're Doing
Testing the 3 Amigos team setup works end-to-end. This is Ring 1 of the presentation.

## Steps
1. Run `/three-amigos` — the skill has the full process
2. Feature to discover: `/color` — status bar color syncs with context window health (green → yellow → red)
3. Spawn a team with Liz, Kent, Claude as teammates
4. Verify they respond, can message each other, and write to their scratch pads
5. Facilitate a real discovery conversation — not a test, actually run it

## Known Issues
- Teammates MUST respond on first prompt or they get stuck idle forever
- Always include "REPLY to me" in spawn prompt
- Agent definitions are at `.claude/agents/liz.md`, `.claude/agents/kent.md`, `.claude/agents/claude.md`
- Scratch pads go to `~/.claude/plans/<feature>-<name>.md`

## Source Code
- Dude gem: this repo
- Claude Code source (READ ONLY): `~/dev/ext/claude-code/`
