---
description: Send a message to another dude
argument-hint: <dude> <text>
---

Send a message to another dude's inbox.

1. Parse `$ARGUMENTS` — first word is target dude name, rest is the message text
2. Error if no arguments or no text provided
3. Resolve sender: read `name` from `{cwd}/.claude/dudes/status.json`
4. Resolve target inbox:
   - Follow symlink `~/.claude/dudes/{name}` → `{resolved}/dudes/inbox.json`
   - Error if symlink or inbox doesn't exist
5. Append message using jq:
   ```
   jq --arg from "{sender}" --arg text "{text}" '. += [{"from": $from, "text": $text, "status": "new"}]' {inbox_path} > {inbox_path}.tmp && mv {inbox_path}.tmp {inbox_path}
   ```
6. Confirm: "sent to {name}"
