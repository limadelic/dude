---
name: 3-amigos
description: Discovery phase — Liz, Kent, Dude discover WHAT before code
---

# Three Amigos

Deliberate Discovery session using Example Mapping. Three agents as a team, you as the lead.

## Setup

- Use `/sup` to start the team with the cast below
- Build the brief with the user before spawning — use the template in `BRIEF.md` to structure the conversation naturally
- Send the completed brief as the spawn prompt to all three — do NOT rely on follow-up SendMessages
- Idle notifications are normal — teammates go idle after every turn. Idle does NOT mean stuck. Wait for their reply, don't resend the brief.
- Confirm each teammate replies before proceeding
- Do NOT start the session until all three have said hello

## The Cast

Spawn each with EXACTLY these names and subagent types:

| Name   | subagent_type | Model | Role                                                    |
|--------|---------------|-------|---------------------------------------------------------|
| liz    | liz           | opus  | hunts for ignorance, surfaces assumptions, drives examples |
| kent   | kent          | opus  | checks feasibility, grounds in code, simplifies          |
| dude   | dude          | opus  | guards ubiquitous language, knows both codebases, thinks as the user  |

All three MUST run on Opus. You facilitate — you don't tell them what to think.
Use these exact `name` values when spawning — no variations, no suffixes.

## Example Mapping

Think in terms of cards:

- **Yellow (Story)**: the feature — you present this at the start
- **Blue (Rules)**: business rules that emerge from discussion
- **Green (Examples)**: concrete "when THIS, then THAT" under each rule
- **Red (Questions)**: unknowns to resolve or park

## Tasks

Create these two tasks when the session starts:

- **Amigos respond to discovery** — Facilitate the team discussion. Route tensions, cross-pollinate, resolve red questions. Mark complete when converged or time's up.
- **Write discovery plan** — Synthesize the amigos' output into `~/.claude/plans/<feature>-examples.md` with yellow/blue/green/red cards. Blocked by the first task.

## The Flow

- Pass the problem to all three — include known constraints upfront
- Each thinks and replies with their take — no pad files, just messages
- You're the switchboard:
  - Route tensions: "Liz raised X — Kent, is that feasible?"
  - Challenge: "Dude says the term is Y, Liz you used Z — which is right?"
  - Push back yourself — you have opinions too
- Repeat until converged or going in circles
- YOU write the final plan to `~/.claude/plans/<feature>-examples.md`

## Time Limit

- 25 minutes max — if not converged by then, the story is too big or the unknowns are too deep
- Kick a `/pomo` at the start to track the clock
- Shut down the team when time's up
- Write the plan with whatever you have — parked questions are fine

## Exit Criteria

- No unresolved red cards (or explicitly parked for later)
- Examples cover happy path + edge cases
- All three agree on the rules and examples
- Glossary updated if new terms emerged
- Examples are feasible (Kent confirmed) and use correct language (Dude confirmed)


## Rules

- NO touching code — read only, never edit
- NO Gherkin — plain language examples only
- NO solutions — discovery only
- NO pad files — amigos think and reply, you synthesize
- Only YOU write the final plan
- The conversation IS the value
- Independence first — let each amigo form their own take before cross-pollinating
