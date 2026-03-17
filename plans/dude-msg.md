# /msg skill — Issue #37 (limadelic/dude) ✅

## What
`/msg {dude} {text}` — append a message to target dude's inbox.json

## How it works

### Sender identity
- Reads `name` from `{cwd}/.claude/dude/status.json`
- Set by `/pub` at registration time — no basename guessing

### Target resolution
- Follows symlink `~/.claude/dudes/{name}` → `{resolved}/dude/inbox.json`
- All dudes are reachable via symlinks — including global sup as "dude"

### Message envelope
```json
{"from": "dude", "text": "hey"}
```
- Just `from` and `text` — no timestamp, no read flag until needed
- Handler removes entry after processing (future story)

### Append via jq
```sh
jq --arg from "$from" --arg text "$text" \
  '. += [{"from": $from, "text": $text}]' \
  inbox.json > inbox.json.tmp && mv inbox.json.tmp inbox.json
```
- Always appends to end — FIFO queue
- Atomic write via tmp file

## Depends on
- /pub (#36) ✅ — dudes register, get inboxes and symlinks

## Tested
- dude → rec (2 messages, verified append order)
- dude → smith (3 messages, verified jq append)
- rec → smith (cross-project)
- rec → dude (project back to global sup via symlink)

## Not in scope
- Inbox watching (await) — separate story
- Sub dude resolution — phase 2
- Reply mechanism — comes with inbox watching
