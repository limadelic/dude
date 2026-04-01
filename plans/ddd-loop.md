# DDD — Dude-Driven Development

The outer loop. Feature-level. Lisa writes scenarios, Eric reviews domain language, Dude approves, Katmandu makes it pass, Lisa verifies.

## The Three Loops

```
DDD (feature)
  └── Katmandu (task)
        └── TCR/Ralph (code)
```

DDD produces scenarios as specs. Katmandu picks them up and makes them pass. TCR is how Kenny actually writes the code.

## The Steps

0. Three Amigos (optional) — discover WHAT
1. Lisa writes scenarios — no step defs yet
2. Eric reviews — domain language, glossary drift, new terms
3. Dude approves — if Eric flagged terms, decide now
4. Lisa writes step defs — @wip, pending for Kenny
5. Eric reviews steps — domain alignment
6. Katmandu — make steps pass (middle loop kicks in)
7. Lisa verifies — green removes @wip, red goes back to 6

## Glossary Maintenance

Eric flags new terms during reviews. Dude decides if they belong. Update the Ubiquitous Language section in DDD SKILL.md. Commit with the feature.

## What We Learned

- The glossary had "finish" but the CLI uses "abided" — mismatch. Glossary must reflect actual code.
- /reply was missing from the glossary entirely. We discovered it through building the knock-knock scenario. Glossary grows as you build.
- DDD is not rigid. Sometimes you skip Three Amigos and just say "fix this." That's Katmandu directly. DDD is for when you're building features.
- The domain expert is dude (Claude Code). www the docs AND read the source at ~/dev/ext/claude-code/ for terms.
- ATDD was redundant — same loop without the domain context. Deprecated, now redirects to /ddd.

## Status

Skill updated at `.claude/skills/ddd/SKILL.md`. ATDD deprecated. CLAUDE.md references /ddd.
