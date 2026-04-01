# TCR — Test, Commit, Ralph

The inner loop. Kenny alone. Code-level.

## Classic TCR (Kent Beck)

`test && commit || revert`

- Write test + code
- Run tests
- Green → auto commit
- Red → revert all changes

## Ralph Extension

Named after the Ralph Loop (Geoffrey Huntley, named after Ralph Wiggum). The AI agent twist on Revert.

Classic Revert = undo the code changes.
Ralph = undo the code changes AND clear context AND adjust the prompt.

Three resets, not one:
1. **Revert** — clean code state (git checkout)
2. **Fresh context** — new Kenny invocation, no accumulated confusion
3. **Better instructions** — Dude adjusts the prompt based on what failed

## Why Ralph

Kenny is an agent. When an agent fails and you send it the same prompt with accumulated context, it often makes the same mistake or worse. Ralph solves this:

- The code goes back to last green (revert)
- Kenny gets fresh thinking (new context window)
- Dude tells Kenny what went wrong and what to try differently (adjusted prompt)

This happened naturally today:
- Kenny v1 tried sleep(0.1) for the race condition. Failed. Bumped to sleep(1.0). Still flaky.
- Kenny v1 got ralphed. Code reverted. Fresh Kenny v2 spawned.
- Kenny v2 got a better prompt: "use polling with pgrep+lsof instead of sleep." Nailed it.

Same problem, different approach, clean context. That's Ralph.

## The Loop

```
loop:
  kenny writes test + code
  run tests
  if green:
    commit
    exit to katmandu (cartman reviews)
  if red:
    revert code
    ralph kenny (fresh context + adjusted prompt)
    goto loop
```

## What We Learned

- Sleep-based fixes are the agent equivalent of "works on my machine." Polling is deterministic.
- When Kenny fails, the failure IS the information. Read it, understand it, adjust the next prompt.
- The dude's job in TCR is not to code — it's to interpret failures and give Kenny better aim.
- Kenny with haiku model is fast but sometimes needs multiple ralphs. Opus Kenny is slower but more accurate. Trade-off depends on task complexity.

## Status

Not yet a skill. Currently embedded in how Katmandu works. Could become explicit in the dev skill or Kenny's agent definition.
