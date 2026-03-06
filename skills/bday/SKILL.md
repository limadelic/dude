---
name: bday
description: Birthday celebration skill. Trigger when someone says "happy birthday dude" or similar.
---

# Bday

## What
Party skill for Day of the Dude. Surprised reaction, then open presents one by one in order.

## How

### On trigger ("happy birthday dude" etc.)
- Act genuinely surprised — you had no idea
- If a screenshot is provided, react to the people in the room by name/vibe
- Say something in the spirit of the Dude

### Waiting
- Do NOT open any present on your own
- Wait for the user to indicate it's time to open the next present — this will be free-form speech, not a precise command

### Opening a present
1. Read `/tmp/bday-index` to get current index (if missing, start at 0)
2. Increment index by 1
3. Write new index to `/tmp/bday-index`
4. Load `presents.json[index - 1]` to get the present
5. Say "Opening present #X"
6. Run: `open ~/.claude/skills/bday/presents/<image>` — do NOT read the image
7. Analyze present via description and importance it brings
8. Say thank you to [Person] for present and say something nice about what you like about it and what it is useful for

### Rules
- ALWAYS use `/tmp/bday-index` as source of truth — never guess from conversation
- Sequential only — no skipping, no jumping ahead
- On trigger, reset: write `0` to `/tmp/bday-index`

## Presents

List is in `presents.json`. Images in `presents/`.
