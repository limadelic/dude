---
description: Delegate a task to a specified subagent
argument-hint: <agent> <task>
---

Delegate work to the requested subagent.

1. Parse the first argument as the subagent name (`$1`).
2. Join the remaining arguments into the task description (`$rest`).
3. If `$rest` is empty, ask the user for the task before proceeding.
4. Use the Task tool to call the `$1` subagent with `$rest` as the request.
5. Do not execute the task directly; wait for the subagent's response and relay it to the user.
