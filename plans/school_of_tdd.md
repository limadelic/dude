# Plan: dude_school_tdd

Establish TDD rules for the dude dev skill. Two gaps to fill.

## Context

Katmandu loop: kent analyzes → kenny implements → cartman reviews.
Katmandu README describes GOOS outside-in flow but neither kent nor kenny have rules for it.
paperboy_spec.rb is the approved reference implementation for spec style.

## Gap 1: specs.md — Dude School mocking patterns (for kenny)

Current specs.md has Detroit School rules (shared before, relaxed mocks, no .with). Wrong.

### Dude School pattern (from paperboy_spec):
- `let(:dep)` — instance_double of the dependency
- `let(:sut)` — `described_class.new` (default constructor, no DI in test)
- `before` — `allow(DepClass).to receive(:new).and_return(dep)` (mock Class.new)
- Each test inline: stub dep (arrange), call sut (act), assert result + have_received (assert)
- NO shared stubs in before beyond Class.new
- NO let for stubs
- NO comments

### Still needs:
- User approval on paperboy_spec as THE reference
- Rewrite specs.md Mock Style section
- Apply pattern to sommelier_spec and news_spec to prove it works

## Gap 2: kent.md — GOOS outside-in analysis rules (for kent)

Kent analyzes and decomposes but has no rules on HOW.

### What's missing:
- Outside-in: start from failing acceptance scenario, work inward layer by layer
- Each layer's test drives the design of the layer beneath
- Discover interfaces through what the SUT needs from its collaborators
- Mock roles not objects — collaborator = a role the SUT needs fulfilled
- Identify layers: scenario → command/entry point → domain → infrastructure
- Each task kent produces should say WHAT class, WHAT role it plays, WHAT it needs from deps

### Still needs:
- Research + draft of outside-in analysis rules
- User review and approval
- Update kent.md

## PR 161 blockers (paused)

These are on hold until dude_school_tdd is established:

| # | File | Comment | Status |
|---|------|---------|--------|
| 7 | news_spec.rb:54 | garbage test | pending |
| 9 | news_spec.rb:60 | mocking wrong | blocked |
| 10 | sommelier_spec.rb:9 | mocking wrong | blocked |
| 11 | cuke/news.rb:97 | ! implementation wrong | blocked |
| 12 | dudes_steps.rb:99 | completely wrong | blocked |
| 13 | dudes_steps.rb:51 | wrong abstraction | blocked |

## What got done today

- PR 161 comments 1-6: fixed (news.rb refactor, paperboy spec rename)
- Researched London School TDD (GOOS, Pryce/Freeman)
- Established paperboy_spec as reference implementation
- Identified the two gaps (specs.md + kent.md)
