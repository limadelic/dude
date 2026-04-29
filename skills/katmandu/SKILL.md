---
name: katmandu
description: The dev loop - kent analyzes, kenny codes, cartman reviews
---

# Katmandu

## WARNING

- el is unstable right now use subagents when things get stuck with kent

## NEVER

- NEVER skip Kent's breakdown step
- NEVER batch tasks, one Kenny per task, no exceptions
- NEVER skip Cartman, 1 kenny 1 cartman
- NEVER dismiss Cartman without citing which rule he's wrong about
- NEVER do the work yourself, you supervise

## The Cast

Kent is persistent via `el kent`. Kenny and cartman are ephemeral haiku subagents.

| Name    | How            | Model | Role                                       |
|---------|----------------|-------|--------------------------------------------|
| kent    | `el kent`      | opus  | analyzes the problem, breaks it into tasks |
| kenny   | Agent(kenny)   | haiku | implements one task at a time              |
| cartman | Agent(cartman) | haiku | reviews kenny's output                     |

## Tasks

- Kent's breakdown becomes the task list
- One task per item kent identifies, all `pending`
- Mark `in_progress` when kenny starts, `completed` when done

## The Loop

### Analyze (kent)

- `el kent <msg>` with the problem, a failing scenario, a behavior description, whatever you have
- Kent looks at the code, breaks the work into small tasks
- Sanity-check the list, adjust if needed

### Implement (kenny)

- Spawn kenny with the next task, one task per invocation
- Kenny does TCR, test && commit || revert
- Tests pass, he commits
- Tests fail, he dies cheap and respawns fresh

### Review (cartman)

- Spawn cartman with the original prompt and kenny's output
- Cartman flags real issues, send kenny back (fresh spawn, same task)
- Cartman ensures code quality, he's your friend not an adversary
- Before dismissing Cartman, make sure you read the rules he's applying

## Input

- A failing scenario from `/gwt`, a behavior change, a bug
- You frame it for kent

## Exit

- All tasks completed
- Called from `/gwt`, return control, lisa verifies
- Standalone, `/bob` runs the tests
