# Fix Benito CI

## Problem

`claude-code-action` in **tag mode** doesn't resolve `.claude/commands/benito.md`. When someone comments `@benito`, the action passes the raw comment text `@benito` to Claude. Claude doesn't see the command file, so it does a single generic review instead of running the three sub-skills (`/review`, `/rec-review`, `/reversible`).

## What We Proved

- `prompt: "Run /benito"` in `benito.yml` makes it work — Claude Code CLI resolves the command file and runs all three skills.
- But `prompt` switches `claude-code-action` to **agent mode**, which loses the rich GitHub PR context (diff, comments, review threads) that **tag mode** provides.
- Without PR context, Claude can still fetch it via `gh pr diff`, but it's not automatic.

## Root Cause

`claude-code-action` has two modes:
- **Tag mode**: rich PR context, but only passes comment text as instruction — no command file resolution
- **Agent mode**: resolves commands via CLI, but minimal context

We need both: rich PR context AND command file resolution.

## Options

1. **Use `prompt` + explicit PR context** — Pass `prompt: "Run /benito"` and let Claude fetch PR context itself via `gh pr diff`. Downside: loses automatic context injection (review comments, CI status, etc.)

2. **Contribute upstream** — Open an issue/PR on `anthropics/claude-code-action` to support `.claude/commands/` resolution in tag mode. This is the proper fix.

3. **Inline the prompt** — Pass benito's full instructions as the `prompt` value in `benito.yml`. Duplicates the content but works with agent mode. Defeats the purpose of the command file.

4. **Hybrid: prompt + trigger_phrase** — Test if both can coexist. Pass `prompt: "Run /benito"` alongside `trigger_phrase: "@benito"`. If the action gives Claude both the PR context AND the prompt, this might just work. We saw hints of this in the logs but didn't fully test it.

## Recommended: Option 4 first, Option 2 as follow-up

## Testing

1. Add `workflow_dispatch` back to `benito.yml` with a `benito-test` job on a branch
2. Trigger with `gh workflow run benito.yml --ref <branch> -f pr_number=<PR#>`
3. Check logs for both PR context AND command file resolution
4. If works, PR to main

## Files

- `.github/workflows/benito.yml`
- `.github/workflows/claude.yml`
- `.claude/commands/benito.md`
