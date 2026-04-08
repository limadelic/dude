---
name: 3-amigos
description: Discovery phase — Liz, Kent, Dude discover WHAT before code
---

# Three Amigos

Deliberate Discovery session using Example Mapping. Three agents as a team, you as the lead.

## Setup

- Use `/sup` to start the team with the cast below
- Include the FULL feature brief with all known constraints in each spawn prompt — do NOT rely on follow-up SendMessages for the brief
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

1. **Amigos respond to discovery** — Facilitate the team discussion. Route tensions, cross-pollinate, resolve red questions. Mark complete when converged or time's up.
2. **Write discovery plan** — Synthesize the amigos' output into `~/.claude/plans/<feature>-examples.md` with yellow/blue/green/red cards. Blocked by task 1.

## The Flow

1. Pass the problem to all three — include known constraints upfront
2. Each thinks and replies with their take — no pad files, just messages
3. You're the switchboard:
   - Route tensions: "Liz raised X — Kent, is that feasible?"
   - Challenge: "Dude says the term is Y, Liz you used Z — which is right?"
   - Push back yourself — you have opinions too
4. Repeat until converged or going in circles
5. YOU write the final plan to `~/.claude/plans/<feature>-examples.md`

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
