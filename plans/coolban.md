# Coolban

Label-driven kanban for dude agents. Labels are the kanban cards.

## Trigger

GHA workflow on `pull_request: labeled` with labels: `3-amigos`, `gherkin`, `katmandu`.

## Setup

- One branch, one PR per issue (covers all loops)
- PR and branch created before labeling (manually or via alley-pr, separate from coolban)
- Issue linked to PR — issue body is the work description

## Flow

1. You label the PR with a loop label (e.g. `katmandu`)
2. GHA fires, spins up a dude (Claude Code)
3. Dude reads the linked issue for context
4. Dude runs the matching skill (3-amigos / gherkin / katmandu)
5. Dude pushes to the PR branch
6. Done → PR ready for review
7. Timeout → document progress in the issue, retry (up to 3 attempts)
8. You review, label next loop on same PR, repeat

## Attempts

- 30 min timeout per attempt
- 3 attempts max per label
- Each attempt documents what it did / where it got stuck in the issue
- Next attempt reads previous notes, picks up from accumulated branch state
- After 3 failures → flag for human review

## Board

- Single board: Tao (UKGEPIC/projects/156/views/1)
- No column automation — labels drive everything
- PR review flag when dude is done
- You review the PR directly

## Labels

| Label | Skill | Output |
|-------|-------|--------|
| 3-amigos | /3-amigos | Discovery artifacts |
| gherkin | /gherkin | Feature files |
| katmandu | /katmandu | Code + specs |

## Attempt tracking

- GHA workflow manages attempt counter (1-3)
- Each attempt documents progress/failure in issue comment
- Next attempt reads previous comments for context
- After 3 failures → remove loop label, flag for human

## What we need

- [ ] GHA workflow file (on PR labeled, attempt loop, 30 min timeout)
- [ ] Label setup on repo (3-amigos, gherkin, katmandu)
- [ ] Claude Code setup in GHA (clone repo, cd code, run skill)
