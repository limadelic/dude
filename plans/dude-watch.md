# watch — baked into /pub (issue #38)

## What
Inbox watching is implicit in `/pub` — not a separate command.

## /msg sets `status: "new"` on sent messages

## New command: /abide
Reads and processes first unhandled message:
1. Read first msg where `status == "new"` from `{cwd}/.claude/dudes/inbox.json`
2. `TaskCreate` with msg content
3. Set `status: "wip"` on that msg in inbox.json
4. (later) Reply, remove the message, then re-arm watcher

## Steps (to add to pub.md step 5)

5. Arm watcher: run `wait-until.sh "jq -e 'length > 0 and .[0].status == \"new\"' {cwd}/.claude/dudes/inbox.json" 5` in background (run_in_background: true). When it fires, run `/abide`.

## Test
- inbox has `[{"from": "smith", "text": "zup dude", "status": "new"}]`
- run `/abide` → should detect it and create a todo, set wip
