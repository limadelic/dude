---
name: ddd
description: Dude-Driven Development — discovery through build with glossary maintenance
---

# DDD (Dude-Driven Development)

## Domain

Two codebases, one domain:

1. **Dude** (~/.claude/) — the whole project. Everything here is fair game.
   - **Dude gem** (~/.claude/code/) — the Ruby gem. CLI, domain code. Skills/agents/commands delegate to this.
   - **Dude config** (~/.claude/code/.claude/) — skills, agents, commands specific to building the gem.
   - Global config, plans, teams — all under ~/.claude/
2. **Claude Code** at ~/dev/ext/claude-code/ (READ ONLY) — the platform we wrap. We reverse engineer CC to discover what it exposes. We NEVER modify CC — we build around it in Dude.

To act as domain expert: www the CC docs AND read the CC source for the right terms. But solutions always land in Dude.

## Code vs Shell

Anything deterministic belongs in the Dude gem (Ruby). Shell scripts are fine for POCs but ultimately the logic moves to Ruby — keeps the model simple and DRY. Skills/agents/commands delegate to gem code, not the other way around.

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

Run `/three-amigos` to discover WHAT before writing Gherkin.

### 1. Gherkin

Run `/gherkin` — the full scenario-by-scenario loop with Lisa and Eric.

## Glossary Maintenance

**Who**: Eric flags, Dude decides
**When**: During each loop (steps 2, 3, 5)
**Where**: Ubiquitous Language section above
**Commit**: Glossary updates ship with the feature
