---
name: news
description: First, trigger the dude GHA to test the latest release
---

# news

Run `dude news` to fetch and display the latest release news.

## Commands
- `/news` — display latest news (default limit 5)
- `/news --limit N` — display latest N items

## Rules
- Delegates directly to the CLI.
- Simply runs `dude news` with optional `--limit` argument.
- No implementation details needed — the CLI handles everything.
