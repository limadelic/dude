---
name: news
description: Find out latest features and bug fixes. Test the latest release to see if we can update.
---

# news

## How
- Delegate to a haiku subagent (`model: "haiku"`, `run_in_background: true`)
- Subagent runs: `dude news > /tmp/dude-news.md 2>&1` (or add `--limit N`)
- After subagent completes, Read `/tmp/dude-news.md` and cat the full contents
- No summary, no reformatting
- If subagent errors, STOP and ask
