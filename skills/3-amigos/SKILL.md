---
name: 3-amigos
description: Discovery phase. Liz, Kent, Dude discover WHAT before code
---

# Three Amigos

- Deliberate Discovery session using Example Mapping
- Three agents as a team, you as the lead

## Setup

- `/sup` the team with the cast below
- Build the brief FIRST using BRIEF.md template
- Don't spawn until user confirms the brief
- Send the completed brief as the spawn prompt to all three
- Do NOT rely on follow-up SendMessages
- Idle notifications are normal, teammates go idle after every turn
- Idle does NOT mean stuck, WAIT, don't resend, don't nudge
- Confirm each teammate replies before proceeding
- Be patient with Opus on complex prompts
- Do NOT start the session until all three have said hello

## The Cast

| Name   | subagent_type | Model | Role                                                    |
|--------|---------------|-------|---------|
| liz    | liz           | opus  | hunts for ignorance, surfaces assumptions, drives examples |
| kent   | kent          | opus  | checks feasibility, grounds in code, simplifies          |
| dude   | dude          | opus  | guards ubiquitous language, knows all three layers (El/Dude/CC), thinks as the user  |

- All three MUST run on Opus, you facilitate, you don't tell them what to think
- Use these exact `name` values when spawning, no variations, no suffixes

## Example Mapping

- **Yellow (Story)**: the feature, you present this at the start
- **Blue (Rules)**: business rules that emerge from discussion
- **Green (Examples)**: concrete "when THIS, then THAT" under each rule
- **Red (Questions)**: unknowns to resolve or park

## CRC Cards

| Object | Responsibilities | Collaborators |
|--------|---------|-------|
| name   | what it does, what it knows | who it talks to |

- As scenarios emerge, discover objects using CRC cards (Beck & Cunningham, 1989)
- Walk each scenario: who acts? who knows? who delegates?
- Scenarios are the input, CRC cards are the design that emerges

## Tasks

- **Amigos respond to discovery**
  - Facilitate the team discussion
  - Route tensions, cross-pollinate, resolve red questions
  - Mark complete when converged or time's up
- **Write discovery plan**
  - Synthesize into `~/.claude/plans/<feature>.md`
  - Include yellow/blue/green/red cards and CRC cards
  - Blocked by the first task

## The Flow

- Pass the problem to all three, include known constraints upfront
- Each thinks and replies with their take, no pad files, just messages
- You're the switchboard:
  - Route tensions: "Liz raised X, Kent, is that feasible?"
  - Challenge: "Dude says the term is Y, Liz you used Z, which is right?"
- Repeat until converged or going in circles
- YOU write the final plan to `~/.claude/plans/<feature>.md`

## Time Limit

- 25 minutes max, if not converged the story is too big or the unknowns are too deep
- Shut down the team when time's up
- Write the plan with whatever you have, parked questions are fine

## Exit

- No unresolved red cards (or explicitly parked for later)
- At least one concrete end-to-end happy path example
- Edge cases covered after the happy path
- All three agree on the rules and examples
- Glossary updated if new terms emerged
- Examples are feasible (Kent confirmed) and use correct language (Dude confirmed)

## Rules

- NO touching code, read only, refactoring encouraged
- NO Gherkin, plain language examples only
- NO solutions, discovery only
- NO pad files, amigos think and reply, you synthesize
- Only YOU write the final plan
- The conversation IS the value
- Independence first, let each amigo form their own take before cross-pollinating
- ALL THREE must reply
- If one never responds, the session is NOT complete
- Tear down and restart
- NEVER write a plan with missing voices
