---
name: news
description: Find out latest features and bug fixes. Test the latest release to see if we can update.
---

# news

## Current Concern

Haiku delegation breaks on new Claude Code releases. Always taste with a prompt that tests this.

## How
- Delegate to a haiku subagent (`model: "haiku"`, `run_in_background: true`)
- Subagent runs: `dude news -t "delegate to a haiku subagent and have it return hello" > /tmp/dude-news.md 2>&1` (or add `--limit N`)
- After subagent completes, Read `/tmp/dude-news.md` and cat the full contents
- No summary, no reformatting
- If vintage fails, do NOT upgrade, report the failure
- If subagent errors, STOP and ask
