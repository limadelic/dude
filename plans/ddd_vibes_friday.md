# DDD Vibes — Friday Presentation

## The Bit
DDD means Domain-Driven Design. DDD also means Dude-Driven Development. Same initials, same principles, different rug.

## The Visual
Concentric loops zooming in. Keynote drills from outer to inner:
- **Center: The Dude** — Vitruvian Dude (Da Vinci style)
- **Ring 1: 3 Amigos** — discovery loop, Opus level
- **Ring 2: Dev Loop** — katmandu, Kenny drops to Haiku

## The Feature
`/color` — status bar color syncs with context window health (green → yellow → red as context rots). Small, visual, end-to-end.

## Ring 1: Three Amigos

### Setup
- **Me (lead)**: orchestrate the team, facilitate, decide
- **Liz** (new agent): discovery through examples — "give me a scenario, what happens when..." — Liz Keogh energy, Deliberate Discovery, surfaces assumptions
- **Kenny** (existing agent): developer amigo — thinks about how to build it, at Opus level in this ring
- **Claude** (new agent): the domain expert — knows itself as the software, reads its own source code, knows where features fit

All three run as Agent Team teammates with persistent context. They talk to each other and to me. Real conversation, not reports.

### What the 3 Amigos Produce
- High-level scenarios discovered through conversation (not full stories — just enough to feed Ring 2)
- Shared understanding of WHAT and WHERE in the codebase
- Glossary updates if new terms emerge

### Agents to Build
- [x] `liz` agent definition — .claude/agents/liz.md
- [x] `kent` agent definition — .claude/agents/kent.md
- [x] `claude` agent definition — .claude/agents/claude.md

### How to Run the 3 Amigos Team

```
# 1. Create team
TeamCreate: team_name: "3-amigos", description: "Discovery phase"

# 2. Spawn all three with their agent definitions
Agent: subagent_type: liz, name: liz, team_name: 3-amigos, run_in_background: true
  prompt: "You are Liz. Read ~/.claude/plans/color-liz.md for context.
  [describe the feature]. Surface unknowns, ask 'what happens when...'
  Write thinking to ~/.claude/plans/<feature>-liz.md. REPLY to me."

Agent: subagent_type: kent, name: kent, team_name: 3-amigos, run_in_background: true
  prompt: "You are Kent. Read ~/.claude/plans/color-kent.md for context.
  [describe the feature]. Read CC source at ~/dev/ext/claude-code/.
  Write findings to ~/.claude/plans/<feature>-kent.md. REPLY to me."

Agent: subagent_type: claude, name: claude-amigo, team_name: 3-amigos, run_in_background: true
  prompt: "You are Claude. Read ~/.claude/plans/color-claude.md for context.
  [describe the feature]. Check CC docs (www) and source. Guard the language.
  Write findings to ~/.claude/plans/<feature>-claude.md. REPLY to me."

# 3. Facilitate — read pads, cross-pollinate, challenge
# 4. When converged — write final plan to ~/.claude/plans/<feature>-examples.md
# 5. Shutdown teammates, TeamDelete
```

### Lessons Learned
- Teammates MUST respond on first prompt or they get stuck in idle loop forever
- Always include "REPLY to me" in spawn prompt
- Liz agent had issues — may need to force initial engagement
- Pads at ~/.claude/plans/ work great for async scratch thinking
- Lead carries context between stateless respawns

## Ring 2: ATDD Loop (Sonnet)
- **Lisa** (Lisa Crispin) — team agent (team of one), persistent context, turns Ring 1 examples into Cucumber scenarios one at a time
- **Eric** (already exists) — regular subagent, stateless, reviews each scenario
- **Me** — oversees the loop, syncs Eric's feedback back to Lisa
- Loop: Lisa writes one → Eric reviews → accepted or pushed back → next
- No production code — just executable specs
- Model: Sonnet for both Lisa and Eric

## Ring 3: Katmandu Loop (Haiku)
- One accepted scenario from Ring 2 feeds in as the task
- **Kenny** codes (Haiku) — behavior description, not implementation details
- **Cartman** reviews kenny's output
- **Dude** decides — real violations go back to kenny, nitpicks mean we're done
- Commit after each task exits the loop
- Chase the green bar on the acceptance test from Ring 2

## Ring 4: TCRalph Loop (innermost)
- Kenny's inner coding loop — a ralph loop with TCR
- Each iteration: kenny gets the task with fresh context, writes code, TCR runs
- Green: tests pass → commit → done
- Red: tests fail → revert → kenny dies → fresh context → loop
- "Oh my god, they killed Kenny!" — ralph loop meets South Park
- Kent Beck's TCR + Geoffrey Huntley's ralph loop
- Dude manages the cycle

## Open Questions
- How much backstory on the dude system for the audience?
- Audience — who are they, what do they know?
- Team setup — is CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled?
