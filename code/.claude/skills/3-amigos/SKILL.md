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
