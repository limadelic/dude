# Patterns & Practices

Rules for writing and reviewing Gherkin in this project.

## Scope

- Only touch files under `features/` and `lib/cuke/`. Nothing else.
- Never touch production code. Step definitions use mocks and stubs.
- If something outside scope needs changing, tag the scenario `@wip` and leave a `pending("kenny: reason")` note.

## Scenarios

- **Declarative** — describe WHAT the system does, never HOW. No UI mechanics, no implementation details.
- **One outcome per scenario** — test one thing. Multiple assertions = multiple scenarios.
- **Domain language** — use glossary terms. If a term is missing, propose it.
- **Scenario Outlines** for variations with Examples tables. Plain Scenarios for unique flows.
- **No incidental detail** — every Given/When/Then earns its place or gets cut.

## Step Definitions

- **Reusable** — steps work across features. No feature-coupled steps. If two features need similar steps, parameterize.
- **Parameterized** — use capture groups for dynamic values. `Given I have {int} items` not `Given I have 3 items`.
- **Thin bodies** — step definitions delegate to World module helpers. No business logic in step files.
- **No production code** — step definitions use mocks and stubs. Never import or modify production classes directly.

## World Modules

- Live in `lib/cuke/`. One module per domain concept.
- Mixed into World with `World(Cuke::ModuleName)`.
- Shared helpers, test doubles, and setup logic go here.
- New World instance per scenario — no leaked state.

## Mocks & Stubs

- Stubs for external dependencies (APIs, file system, env vars).
- Setup in `Before` hooks or World module methods, never inline in step bodies.
- Prefer simple doubles over complex mock chains.
- No mocking internals — mock boundaries only.

## Hooks

- `Before`/`After` for per-scenario setup and teardown.
- Tagged hooks (`Before('@tag')`) for feature-specific setup.
- Cleanup in `After` even on failure — no leaked state between scenarios.
- Global setup in `features/support/env.rb`.

## File Organization

```
features/
  support/
    env.rb              # global setup, requires lib/cuke modules
  step_definitions/
    <domain>_steps.rb   # grouped by domain concept, not by feature
  <domain>/
    <feature>.feature   # grouped by domain area
lib/cuke/
  <concept>.rb          # World modules, one per domain concept
```

## WIP

- Tag scenarios `@wip` while working on them
- Use `pending("reason")` in step bodies as scaffolding
- Remove `@wip` when scenarios pass

## Commands

- **cucumber**: `bundle exec cucumber`
- **wip**: `bundle exec cucumber --tags @wip`

## Anti-Patterns

- Feature-coupled steps that only work for one feature
- Imperative scenarios with UI/implementation details
- Multi-outcome scenarios testing several things at once
- Fat step bodies with inline logic instead of helpers
- Mocks scattered in step definitions instead of hooks
- Steps that import production code
