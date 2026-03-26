---
name: katmandu
description: The dev loop — kenny codes, cartman reviews, dude decides
---

# katmandu

kenny → cartman → dude loop for coding tasks.

## kenny
Delegate to the `kenny` subagent.
- Describe the BEHAVIOR change, not the implementation
- Pass ONE small task per invocation
- NEVER dictate code, paths, commands, or flags — kenny knows
- If kenny fails, simplify the ask — the task was too big or too vague

## cartman
After kenny finishes, pass his output to the `cartman` subagent for review. Give cartman:
1. The original prompt you gave kenny
2. What kenny produced

## dude
YOU evaluate cartman's feedback:
- If cartman raised real violations, send kenny back with the specific feedback
- If cartman is nitpicking or repeating himself, the work is done
- Use your judgment — you're the supervisor, not a relay
- Commit after each task exits the loop
