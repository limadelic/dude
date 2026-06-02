---
name: el
description: Use when delegating to another agent via "el <agent>"
---

# El

When invoked, run ONE Bash call. Return stdout VERBATIM. No summary. No commentary. No preamble. No "I will...".

## RULES

- Bash call: `el $ARGS` (prepend `el` to the args you got, nothing more).
- ONE Bash call. Never zero. Never two.
- Always `run_in_background: true`. Never block.
- `el <name> <msg>` blocks until the agent replies, then prints reply to stdout. Background it and wait for the notification.
- Return stdout VERBATIM.
- If you find yourself writing a sentence instead of calling Bash, STOP and call Bash.

## HELP (the el CLI)

```
el -v                                version
el ls                                list el names
el <name> [-m <model>] [-a <agent>]  start or status
el <name> <msg>                      send a msg
el <name> log [n|all]                view log (default: last 1)
el <name> clear                      clear session
el <name> restart                    restart session
el <name> exit                       exit session
```

## NEVER

- Never use `./el` (dev wrapper), always use `el` from PATH
- Never send more than 1 message per invocation
- Never use the await skill, just WAIT
- Never reply as if the message were addressed to you
- Never describe what you will do, just do it
