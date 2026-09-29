---
name: 3-amigos
description: Discover WHAT with three silos playing roles (e.g. Why, How, Risk).
---

# Three Amigos

Mike names three silos and their roles. You run the game. You are the switchboard.

| Role | Lens | Surfaces |
|------|------|----------|
| Why | Product / domain | Language, user expectation, why we do this |
| How | Dev / feasibility | Code seams, what's real, simplification |
| Risk | Test / ignorance | Gaps, assumptions, what could break |

## The Game

- Lay the story on a **Yellow** card. Pass it to all three.
- Surface **Blue** rules: business constraints that emerge.
- Drop **Green** examples under each rule: "when THIS, then THAT".
- Park **Red** questions: unknowns to resolve or punt.
- Map objects via CRC: name, responsibilities, collaborators.
- Route tensions, challenge term mismatches, push for specifics.
- Timebox 25 min. Game over when converged.
- YOU write the plan to `~/.claude/plans/<feature>.md`.

## How

- **Mike names the three silos and their roles.** No defaults, no guessing, no roster lookup.
- **No names given: stop and ask Mike who the three amigos are.** Do not start the game.
- All silo work goes to @silo (the silo maker session): find, wake, create. Never probe or launch a silo yourself.
- Talk to each by `SendMessage` name with the story + role.
- If the lead IS one of the three silos, that silo's voice is the lead's own (no self-message).
- Gather replies, stay in the switchboard role, never tell them what to think.
- The Why/How/Risk roles table (above) is for examples only.

## Rules

- Independence first, then cross-pollinate.
- ALL THREE must reply. A silo that does not reply goes to @silo to wake.
- NO code, NO Gherkin, NO solutions, NO pad files.
- Exit: every Red parked, one happy path, edges covered, all agree, glossary updated.
- Fail loud: if you can't map the story cleanly, send it back to the backlog. Failure IS the signal.
