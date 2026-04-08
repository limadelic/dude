# Coolban

Label-driven kanban for dude agents. Labels are the kanban cards (Taiichi Ohno style).

## Trigger

- GHA workflow on `issues: labeled`
- `workflow_dispatch` for manual/testing

## Flow

1. You label an issue with a loop label
2. GHA fires, spins up a dude (Claude Code)
3. Dude reads the issue for context
4. Dude runs the matching skill
5. Dude pushes results to the issue's linked branch
6. Done → remove loop label, flag for review
7. Timeout → document progress in issue comment, retry (up to 3 attempts)

## Setup

- One branch, one PR per issue (covers all loops)
- PR and branch created before labeling (manually or via alley-pr, separate from coolban)
- Issue body is the work description

## Attempts

- 30 min timeout per attempt
- 3 attempts max per label
- Each attempt documents what it did / where it got stuck in issue comment
- Next attempt reads previous comments, picks up from accumulated branch state
- After 3 failures → flag for human review

## Board

- Single board: Tao (UKGEPIC/projects/156/views/1)
- No column automation — labels drive everything
- You review the PR directly

## Labels

| Label | Skill | Color |
|-------|-------|-------|
| 🪇 amigos | /3-amigos | orange |
| 🥒 gherkin | /gherkin | green |
| 🏔️ katmandu | /katmandu | white |

## Architecture

- `coolban.yml` — thin wrapper, triggers on label or dispatch, maps label to skill
- `claude.yml` — reusable base (30 min timeout, Claude Code setup)
- Same pattern as benito.yml and dude.yml
- Prompt includes issue number for context (like benito does)

## Open

- [ ] Verify label trigger works from main
- [ ] Skills need to be findable from repo root (code/ subdirectory issue)
- [ ] Attempt counter and retry logic
- [ ] Post Result step (comment output back to issue)
