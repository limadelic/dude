# Plan: spec_mocks

London School TDD — Growing Object-Oriented Software Guided by Tests (Pryce/Freeman)

## Principles

- Every spec has a **SUT** — always real, never mocked
- Dependencies injected via **constructor (DI)**
- **Arrange**: create mocks inline in the test, stub return values, inject into SUT
- **Act**: call ONE method on the SUT
- **Assert**: verify return values AND/OR verify mocks got called (side effects)
- Each test is self-contained — reads top to bottom as a specification
- Mock the **next class only**

## news_spec.rb

| Lines | Violation | Fix |
|-------|-----------|-----|
| 5-16 | Mocks in shared `let` blocks | Move to inline ARRANGE per test |
| 26-32 | ENV setup in shared `before`/`after` | Inline per test |
| 40-48 | Tests stdout output, not return values or mock calls | Assert return values + `have_received` |
| 55-71 | Duplicates entire mock setup instead of being self-contained | Each test arranges its own mocks cleanly |
| 81-84 | `instance_variable_get` — tests internals | Delete |
| 108-114 | `capture_stdout` mutates global `$stdout` | Use RSpec output matchers or test return values |

## sommelier_spec.rb

| Lines | Violation | Fix |
|-------|-----------|-----|
| 8-25 | Mega-stub with `case` routing in shared `before` | Inline stubs per test with `.with` |
| 33-56 | Only asserts return value, never verifies mock calls | Add `expect(mock_gh).to have_received(:run).with(...)` |
| 9-24 | Loose regex matching hides bugs | Use explicit `.with` per call |

## paperboy_spec.rb

| Lines | Violation | Fix |
|-------|-----------|-----|
| 5-6 | Mocks in shared `let` | Move to inline ARRANGE |
| 10-12 | Has `.with` but never verifies call happened | Add `have_received` in ASSERT |
| 15-17, 27-29 | Only tests return value | Also assert the mock interaction |
