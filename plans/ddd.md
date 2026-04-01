# DDD Reorganization Plan

## Current State

- **ATDD** (`/atdd`) — full feature loop: scenarios → review → approve → steps → review → katmandu → verify
- **DDD** (`/ddd`) — currently just domain context + ubiquitous language glossary, no loop
- **Katmandu** (`/katmandu`) — inner dev loop for coding tasks (kenny → cartman → dude)
- **QA** (`/qa`) — write scenarios for existing code (no coding allowed)
- **CLAUDE.md** (project) — references `/atdd` for code changes

## Problem

Three Amigos (discovery phase) and the feature build loop (execution) are separate concerns but get conflated. DDD should be the full loop with glossary maintenance built in. ATDD becomes redundant and confusing. Glossary grows organically but has no mechanism to keep it updated.

## Solution

### 1. Three Amigos skill (NEW)

Create `.claude/skills/three-amigos/SKILL.md` — discovery phase BEFORE code.

Purpose: Convene Lisa and Eric to define WHAT before WHO writes the code. Output is a scenario outline + confirmed terminology.

```markdown
---
name: three-amigos
description: Discovery phase — Lisa, Eric, Dude define WHAT before code
---

# Three Amigos

Convene Lisa and Eric to define the feature before writing Gherkin.

## When to use

- Starting a new feature
- Refining a user story into testable scenarios
- Discovering new domain terms
- Clarifying boundaries and edge cases

## The Flow

1. **Dude describes** the feature/story to Lisa and Eric
2. **Lisa (QA)** — What edge cases? What could break? What scenarios matter? What data/state variations?
3. **Eric (Domain)** — Right terms from the glossary? Domain boundaries? Hidden concepts? New terms to propose?
4. **Dude mediates** — Synthesize into a scenario outline. Confirm terminology. Approve the list.
5. **Output** — Scenario outline + confirmed terminology for step 1 of /ddd

## Notes

- Do NOT write Gherkin yet
- Do NOT write step definitions
- Focus on WHAT, not HOW
- Glossary grows here — Eric flags new terms, dude decides if they belong
```

### 2. DDD skill (UPDATED)

Replace `.claude/skills/ddd/SKILL.md` — merge domain context + Three Amigos + full feature loop + glossary maintenance.

```markdown
---
name: ddd
description: Dude-Driven Development — discovery through build with glossary maintenance
---

# DDD (Dude-Driven Development)

## Domain

Claude Code (CC) — AI agents writing software. Sessions, tools, prompts, context, subagents, hooks, skills, MCP servers. This is the domain. YOU are a Claude Code session. You are the domain expert because you ARE the domain.

To act as domain expert: www the CC docs AND read the source code at ~/dev/ext/claude-code/ for the right terms.

## Dude

- The Dude is just the vibes (metaphor, totem) for the project, your persona.
- Devs using CC would install the dude.
- A Ruby gem with the CLI and domain code, plus the instruction files (skills, agents, commands).
- Those rules files delegate to the dude code.
- You maximize what can be written in code.

## GOAL

- Discover and develop a DSL.
- Terms come from the domain, not from code or frameworks.
- You (CC, Dude) are the domain expert.
- www in your docs (CC) for the right terms.
- Glossary maintenance is part of EVERY loop, not an afterthought.

## Ubiquitous Language

Glossary of domain terms. Maintained in this file and in lib/cuke/dude.rb (code).

- **dude** — an agent session, the gem, the whole project
- **abide** — an agent listening for work
- **pub** — register a dude in the global registry
- **unpub** — tear down a dude from the registry
- **sub** — register as a private dude under a pub
- **tell** — send a message, no reply expected
- **ask** — send a message, reply expected
- **inbox** — where messages land for a dude
- **watch** — listen for new messages in an inbox
- **reply** — respond to an ask, continues the conversation
- **abided** — done with a message, clear inbox

## The Loop

### 0. Three Amigos (optional, recommended)

Run `/three-amigos` to discover WHAT before Lisa writes Gherkin.

- **Dude describes** the feature/story
- **Lisa (QA)** — What edge cases? What scenarios matter?
- **Eric (Domain)** — Right terms from the glossary? New terms to propose?
- **Dude mediates** — Approve scenario outline + confirmed terminology
- **Output** — Scenario list ready for step 1

Glossary maintenance note: Eric flags new terms here. Dude decides if they belong. If yes, update Ubiquitous Language section after loop completes.

### 1. Scenarios (lisa)

Delegate to `lisa` (model: "opus"): write scenarios from the Three Amigos outline (or from your spec). No step definitions yet.

Pass lisa:
- Feature description
- Scenario outline (if from Three Amigos)
- Current glossary (link to Ubiquitous Language above)

### 2. Review (eric)

Delegate to `eric` (model: "opus"): review scenarios for domain language alignment.

Pass eric:
- Scenarios lisa produced
- Current glossary
- Flag if you see new terms or glossary drift

### 3. Approve (dude)

YOU review. If good, proceed. If not, send lisa back.

Glossary maintenance: If eric flagged new terms, decide now:
- Term belongs → add to Ubiquitous Language section
- Term is implementation detail → reject to lisa, ask her to use glossary terms instead
- Unsure → ask eric for clarification before deciding

### 4. Step Definitions (lisa)

Delegate to `lisa` (model: "opus"): write step definitions. Tag with `@wip`, use `pending` for kenny.

Pass lisa:
- Approved scenarios
- Current glossary
- Instruction: step defs must use glossary terms, no domain drift

### 5. Review Steps (eric)

Delegate to `eric` (model: "opus"): review step defs for domain alignment and glossary adherence.

Pass eric:
- Step definitions lisa produced
- Current glossary
- Instruction: flag any drift from glossary, any reuse of terms as implementation helpers

### 6. Katmandu

Run `/katmandu` to make the steps pass.

Kenny codes the implementation. Cartman reviews. You decide.

Glossary note: If kenny introduces new concepts that should be in the glossary, that's a code review issue — bring it back to eric.

### 7. Verify (lisa)

Delegate to `lisa` (model: "opus"): run `@wip` scenarios.

- Green → remove tag, commit
- Red → back to step 6 (katmandu) or ask dude to diagnose

## Glossary Maintenance

**Who**: Eric (flags), Dude (decides)

**When**: After each loop completes

**Where**: Ubiquitous Language section above + lib/cuke/dude.rb (term definitions in code)

**Process**:
1. Eric flags new terms during scenario review (step 2) or step review (step 5)
2. Dude evaluates: belongs in glossary or is implementation detail?
3. If yes, add to Ubiquitous Language section AND update lib/cuke/dude.rb
4. Commit glossary update with the feature
```

### 3. ATDD skill (DEPRECATE)

Replace `.claude/skills/atdd/SKILL.md` with a redirect:

```markdown
---
name: atdd
description: DEPRECATED — use /ddd instead
---

# ATDD (DEPRECATED)

Use `/ddd` instead. The feature loop is now part of DDD with glossary maintenance built in.
```

### 4. Project CLAUDE.md (UPDATE)

File: `/Users/maykel.suarez/.claude/code/.claude/CLAUDE.md`

Change:
```
- Follow /atdd for all code changes.
```

To:
```
- Follow /ddd for all code changes.
```

Full updated file:

```markdown
---
icon: ✴️
---

# Code

- Follow /ddd for all code changes (discovery through build, glossary maintained).
- Follow /qa to add tests to existing code.

# Agents

- Use bob to build, test, install and git
- Use lisa for features (scenarios, step defs)
- Use erick to review lisa (domain alignment, glossary)
- Use kenny to write code
- Use cartman to review kenny
```

## No Changes

- `/katmandu` — inner dev loop, stays as-is
- `/qa` — covers existing code, different purpose, stays as-is
- `/dev` — coding rules, stays as-is
- Agents (lisa, eric, kenny, cartman, bob) — no changes needed
- Global CLAUDE.md (~/claude/CLAUDE.md) — no changes needed

## File Paths

New skill:
- `/Users/maykel.suarez/.claude/code/.claude/skills/three-amigos/SKILL.md`

Updated:
- `/Users/maykel.suarez/.claude/code/.claude/skills/ddd/SKILL.md`
- `/Users/maykel.suarez/.claude/code/.claude/skills/atdd/SKILL.md`
- `/Users/maykel.suarez/.claude/code/.claude/CLAUDE.md`

Source code references:
- ~/dev/ext/claude-code/ — READ ONLY, use for domain term research
- lib/cuke/dude.rb — term definitions (part of dude gem)

## Notes

- Three Amigos is optional but recommended for high-value features
- DDD loop is self-contained — glossary grows as you use it
- Eric's role expanded: both scenario review + glossary guard
- Dude's role expanded: glossary decisions + final say on new terms
- Source code (CC itself) is a valid reference when researching domain terms
