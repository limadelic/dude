---
name: 3-amigos
description: Discovery phase — Liz, Kent, Dude discover WHAT before code
---

# Three Amigos

Deliberate Discovery session using Example Mapping. Three agents as a team, you as the lead.

## Setup

- Use `/sup` to start the team with the cast below
- Confirm each teammate replies before proceeding
- Do NOT start the session until all three have said hello

## The Cast

Spawn each with EXACTLY these names and subagent types:

| Name   | subagent_type | Role                                                    |
|--------|---------------|---------------------------------------------------------|
| liz    | liz           | hunts for ignorance, surfaces assumptions, drives examples |
| kent   | kent          | checks feasibility, grounds in code, simplifies          |
| dude   | dude          | guards ubiquitous language, knows both codebases, thinks as the user  |

All three run as Agent Team teammates (Opus). You facilitate — you don't tell them what to think.
Use these exact `name` values when spawning — no variations, no suffixes.

## Example Mapping

Think in terms of cards:

- **Yellow (Story)**: the feature — you present this at the start
- **Blue (Rules)**: business rules that emerge from discussion
- **Green (Examples)**: concrete "when THIS, then THAT" under each rule
- **Red (Questions)**: unknowns to resolve or park

## The Flow

1. Pass the problem to all three
2. Each writes to their own scratch pad: `~/.claude/plans/<feature>-<name>.md`
3. Read their pads. You're the switchboard now:
   - Decide who needs to hear what from whom
   - Send targeted messages: "Liz raised X — Kent, is that feasible?"
   - Challenge: "Claude says the term is Y, Liz you used Z — which is right?"
   - Push back yourself — you have opinions too
4. They update their pads. You read again. Repeat.
5. All pads are visible to everyone — they can read each other's thinking
6. When pads converge — or you're going in circles — call it
7. YOU write the final plan to `~/.claude/plans/<feature>-examples.md`

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
- Each amigo writes ONLY to their own pad — never to another's
- Only YOU write the final plan
- The conversation IS the value
- Independence first — let each amigo form their own take before cross-pollinating
