# Dudes - Cross-Session Communication

## Goal
Enable independent Claude Code sessions to communicate with each other via file-based messaging. No hierarchy, no orchestrator — just dudes with inboxes.

## Concepts

### Pub Dudes
- Projects/clones already on the machine (rec, smith, etc.)
- Register globally in `~/.claude/dudes/`
- Long-lived, stable — the bounded contexts
- Command: `/pub` — registers this session as a pub dude
- Any pub dude can message any other pub dude

### Sub Dudes
- Scoped inside a pub dude's `{project}/.claude/dudes/`
- Ephemeral, task-driven — come and go based on the work
- Each sub dude gets its own `.claude/` folder for MCP/config/instructions isolation
- Command: `/sub name` — creates a sub dude inside the current dude
- Default: sub dudes talk to their sup, not to other pub's sub dudes
- Nothing prevents direct sub-to-sub if that's what the day calls for

### Sup
- Not a command — a role
- The main session at any level — the one you're talking to
- Rec's sup is the main rec Claude session
- Global sup is `~/.claude` (this session)
- Like an Erlang/OTP supervisor — root of the tree at that level

## Structure

Inbox lives with the dude: `{project}/.claude/dudes/inbox.json`. Global dudes dir is just symlinks for discovery.

```
~/.claude/              (global sup)
  dudes/
    inbox.json          (sup's inbox — always exists)
    rec -> /dev/rec/main/.claude/    (symlink)
    smith -> /dev/self/smith/.claude/ (symlink)

rec/.claude/            (rec's sup)
  dudes/
    inbox.json          (rec's own inbox)
    bob/                (sub dude — ops/build/run)
      .claude/          (bob's config, no MCPs)
      dudes/
        inbox.json
    kenny/              (sub dude — TDD)
      .claude/
      dudes/
        inbox.json
    elizabeth/          (sub dude — browser/visual)
      .claude/          (has Playwright MCP)
      dudes/
        inbox.json
```

- Symlinks give discovery — `~/.claude/dudes/rec` resolves to rec's `.claude/`
- Broken symlink = ghost dude, dead, no cleanup logic needed
- Sup at `~/.claude` has no symlink to itself — it *is* the global

## Skills

### `/pub`
Registers this session as a pub dude. [#36](https://github.com/limadelic/dude/issues/36)
1. Ensures `{project}/.claude/dude/inbox.json` exists — local inbox
2. Creates symlink `~/.claude/dudes/{name} -> {project}/.claude/` — global discovery
3. If running from `~/.claude/` (sup), no symlink — just ensures `~/.claude/dudes/inbox.json` exists

### `/msg`
Sends a message to another dude. [#37](https://github.com/limadelic/dude/issues/37)
- `/msg {dude} {text}` — appends to target dude's inbox.json
- Resolves target via symlink in `~/.claude/dudes/{name}` (pub) or `{project}/.claude/dudes/{name}` (sub)

## Communication
- File-based: `dude/inbox.json` per dude, append messages, watch for changes
- Message envelope: `from`, `text`, `timestamp`, `read`
- Watch mechanism: await skill + filesystem watching (no blocking, no polling loops)
- One message at a time — process, reply if needed to sender's inbox

## Why Not Agent Teams
- Forces leader/spawn hierarchy
- Teammates share leader's MCP config — no isolation
- Assumes one environment (tmux/iTerm2)
- No session persistence — dies when leader dies
- Opinionated and rigid

## One Dude, One Hat

The core insight: you can't fix Claude's limitations with better prompts in the same context window. The context window *is* the problem.

- **Anchoring bias** — Claude can't objectively review code it just wrote. The reasoning tokens that produced the solution bias every subsequent token. A different dude in a clean context sees it fresh.
- **Hat switching degrades both hats** — writing code and testing code in the same session means neither gets done well. The coder tries to make the test pass. The tester goes easy on the code it just saw being written. Separate dudes, separate hats, no contamination.
- **Sub-agents don't specialize** — a sub-agent fires, does a thing, dies. Context gone. Makes the same mistakes next time. A dude *lives* — accumulates expertise from repeated attempts at the same job. Bob fails to start the website, figures it out, remembers next time. A sub-agent never remembers.
- **One hat forever** — Kenny writes code, period. A reviewer dude critiques it cold. Bob builds without caring why it was written that way. Elizabeth tests the UI without knowing what changed. Nobody tries to be good at everything.

This isn't an orchestration framework. It's a structural workaround for a fundamental limitation of how Claude works.

## Context Reset — Small Bets, Not Long Runs

Bigger context windows don't fix context pollution — they just give more room to pollute. A million tokens of unfocused garbage is worse than 200k of tight, relevant stuff.

The industry bets on long-running agents (7-hour sessions, massive autonomy). That's a lottery ticket — sometimes it works, most of the time you get compounding mistakes that nobody catches until the PR is a disaster. Every bad decision becomes context that biases the next decision.

Dudes takes the opposite bet:

- **One scenario at a time** — work maps to ATDD/BDD scenarios. One test, one feature example. The whole tree of dudes works on that single scenario.
- **Green means reset** — when the test passes, all dudes refresh context. Clean slate for the next scenario. No accumulated garbage.
- **Small, verifiable, disposable contexts** — dudes don't need to be smart for long. They need to be smart for *one thing*, prove it with a green test, and reset.
- **Expertise survives resets** — sub-dudes like Bob keep their specialized context (how to build, how to run). The work context resets, the operational knowledge stays.
- **CI for context windows** — small commits, verified individually, don't let garbage accumulate. The same principle that makes CI work for code applies to context management.

This architecture doesn't become wrong regardless of where the curve goes. If context windows get bigger, each dude gets deeper in its specialty — not wider across everything.

## Tests Are Not a Human Limitation

XP, TDD, ATDD/BDD — these practices weren't invented because humans are slow. They exist because complexity needs verification. That doesn't change because the programmer is an AI.

- **Tests are epistemology, not a crutch** — if you can't prove it works, you don't know it works. Doesn't matter how smart you are. The machine tells you whether you're lying to yourself.
- **AI needs tests more, not less** — humans had intuition, muscle memory, years of pattern recognition. Claude has token probabilities. Confidently wrong all the time. A test is the only honest feedback loop.
- **Practices scale to many dudes** — the same discipline that applies to one programmer applies to many. One dude, one hat, one test. Multiply the dudes, the practice stays the same.
- **Not a horseless carriage** — the temptation is to think AI changes everything about how to write software. It doesn't. What changes is *who* writes it and *how many* can work in parallel. The engineering discipline — small steps, verified increments, bounded contexts — those aren't horse practices. They're engineering practices. Cars still need brakes.
- **Future-proof** — even with better models, bigger context, more capabilities, you still can't reason through unbounded complexity. The bigger the thing, the harder it is to change. Tests were never about human limitations. They were about managing complexity. Complexity doesn't care if you're carbon or silicon.

## What Dudes Solves
- **Cognitive isolation** — one dude, one hat, no role switching, no anchoring bias
- **Context isolation** — each dude only carries what it needs
- **MCP isolation** — only the dude that needs Playwright has Playwright (via own `.claude/`)
- **Domain separation** — rec knows C#, smith knows agents, they ask each other
- **Ops separation** — Bob builds, Elizabeth browses, sup thinks
- **Accumulated expertise** — dudes live, learn from failures, get better at their one job
- **IDE-agnostic** — RubyMine, Rider, terminal, doesn't matter
- **No hierarchy enforced** — protocol doesn't restrict who talks to who

## Example: Rec

| Dude | Role | Owns |
|------|------|------|
| sup (main rec) | Domain knowledge, coordination, talks to smith | C# recruiting context |
| bob | Ops — docker, dotnet build, npm, website health | Build pipeline |
| kenny | TDD — writes code and tests | Code changes |
| elizabeth | Browser — visual verification, Playwright | UI testing |

Flow: Kenny writes code → sup tells Bob to recompile → Bob reports back → sup tells Elizabeth to verify UI → Elizabeth reports back. Or: sup tells Kenny to do it and talk to Bob directly. Routing is a decision, not architecture.

## Implementation Phases

### Phase 1 — Basics
- `/pub` skill — ensure local inbox, symlink globally [#36](https://github.com/limadelic/dude/issues/36)
- `/msg` skill — send message to another dude's inbox [#37](https://github.com/limadelic/dude/issues/37)
- Inbox watching via await skill
- Cleanup on exit

### Phase 2 — Sub dude isolation
- Per-sub-dude `.claude/` folders with own MCP config
- Per-sub-dude `CLAUDE.md` with role-specific instructions

### Phase 3 — Cross-project messaging
- Pub dude to pub dude communication
- Rec asks smith agent questions, smith replies

### Phase 4 — Whatever comes next
- Groups/channels
- Sub dude nesting
- Auto-spawning sub dudes based on task type
