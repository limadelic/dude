# Spec Rules

## Philosophy
- mock the next class — each spec tests ONE class
- mock stdlib (File, Dir, JSON) for I/O classes
- no end-to-end through the whole stack

## Mock Style
- relaxed mocks: no `.with` unless testing that specific argument
- shared defaults in `before` — set up the happy path
- each `it` overrides ONLY the one thing that makes that scenario different
- if a test has more than 2 stubs, the extras belong in `before`

## Structure
- spec/ mirrors lib/ — one spec file per class
- helpers/ not support/
- shared examples for repeated patterns

## What to test (BDD)
- test what the caller sees, not how the code works inside
- if you can't observe it from outside the class, don't spec it
- never test: caching, memoization, property assignment, language mechanics
