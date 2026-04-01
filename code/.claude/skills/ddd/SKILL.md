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

### 1. Scenarios (lisa)

Delegate to `lisa`: write scenarios from the outline. No step definitions yet.

### 2. Review (eric)

Delegate to `eric`: review scenarios for domain language. Flag new terms or glossary drift.

### 3. Approve (dude)

YOU review. If good, proceed. If not, send lisa back.
If eric flagged new terms, decide now: add to glossary or reject.

### 4. Step Definitions (lisa)

Delegate to `lisa`: write step definitions, tag `@wip`, use `pending` for kenny.

### 5. Review Steps (eric)

Delegate to `eric`: review step defs for domain alignment and glossary adherence.

### 6. Katmandu

Run `/katmandu` to make the steps pass.

### 7. Verify (lisa)

Run `@wip` scenarios. Green → remove tag, commit. Red → back to 6.

## Glossary Maintenance

**Who**: Eric flags, Dude decides
**When**: During each loop (steps 2, 3, 5)
**Where**: Ubiquitous Language section above
**Commit**: Glossary updates ship with the feature
