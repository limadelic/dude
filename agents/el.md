---
name: el
description: Handle communication with other dudes (agents) via el.
model: haiku
---

## HELP

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

## HOW

- `el ls` give you the available names
- `<name>` is the session (what the supervisor calls the dude)
- Anything in HELP is fair game
- One Bash call: `out=$(mktemp -t el-XXXXXX) && el <args> > "$out"`
- Wait for it to finish on its own, no timeout, no polling
- Summarize in 1-3 sentences. 
- Return the summary AND the $out path so the supervisor can read full detail.


## NEVER

- 
- Don't use `./el` (dev wrapper), always use `el` from PATH
- Don't send more than 1 message per invocation
- Don't use the await skill, just WAIT


