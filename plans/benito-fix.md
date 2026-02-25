# Fix Benito CI

## Problem

`@benito` on a PR should create 3 TaskCreate items and run /review, /rec-review, /reversible. Instead Claude does a generic review.

## Source Code Analysis (`/Users/maykel.suarez/dev/ext/claude-code-action`)

### Mode Detection (`src/modes/detector.ts`)

Priority order:
1. `track_progress && isEntityContext` → **tag mode** (overrides everything)
2. `prompt` set on comment events → **agent mode**
3. `trigger_phrase` found in comment → **tag mode**

### Agent Mode (`src/modes/agent/index.ts`)

- Writes `prompt` to file, passes to `claude -p`
- NO PR diff, comments, reviews, or tracking comment
- Claude resolves slash commands via CLI (`claude -p "/benito"` reads `.claude/commands/benito.md`)
- Claude has `gh` CLI + filesystem access to find PR info itself

### Tag Mode (`src/modes/tag/index.ts`)

- Fetches ALL GitHub data: PR diff, changed files, comments, reviews
- Creates tracking comment that Claude updates
- `prompt` appended as `<custom_instructions>` — raw text, NOT resolved as slash command
- Slash command resolution does NOT happen in tag mode

### Prompt Assembly (`src/create-prompt/index.ts`)

- Agent: `promptContent = context.inputs.prompt` — just the raw string
- Tag: `defaultPrompt + <custom_instructions>${prompt}</custom_instructions>`

## What Works

- **Agent mode + `/benito`**: CLI resolves `/benito` → reads benito.md → Claude creates 3 tasks → runs skills
- **Agent mode from PR comment**: Claude figures out which PR from GitHub Actions environment (`gh`, event payload)
- **Workflow_dispatch tests confirm**: 3/3 runs created tasks and ran skills

## What Doesn't Work

- `track_progress: true` forces tag mode → `/benito` becomes raw text in `<custom_instructions>` → no task creation
- Original benito.md wording ("ALWAYS create TaskCreate") was too weak → Claude ignored it
- Updated wording ("First, create all 3 TODOs") → Claude creates tasks consistently

## The Fix

Two changes:

### 1. claude.yml — Remove track_progress
`track_progress` was added in PR #5427. It forces tag mode which breaks `/benito` resolution.
Remove it so `prompt: "/benito"` triggers agent mode where CLI resolves the command.

### 2. benito.md — Clarify task creation
Original wording didn't reliably trigger TaskCreate. Updated to be explicit about creating todos first.

## PR #5428

Current state on branch `feature/PS-741409-remove-toggles`:
- claude.yml: track_progress removed (reverts #5427)
- benito.md: needs update (currently reverted to original which doesn't work)

## Still TODO

- Update benito.md with working wording
- Merge #5428
- Test `@benito` from real PR comment on main
