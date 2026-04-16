# Patterns & Practices

## Goal

- Maximize reuse of existing DSL
- Minimize new step definitions

## The DSL

### Stub a shell command
```gherkin
* ~ git branch --show-current
  | main |
```

### Execute a shell command for real
```gherkin
* ! mkdir -p .claude
```

### Execute and verify output
```gherkin
* ! readlink dude:
  | .claude |
```

### Run a dude command and verify output
```gherkin
* > /alley-pr:
  | Cannot run on main branch |
```

### Negative assertion (parens = NOT present)
```gherkin
* > /alley-pr:
  | (should not see this) |
```

### Multi-line stubs and assertions
```gherkin
* ~ gh release list
  | v2.1.96 |
  | v2.1.95 |
* > /news:
  | v2.1.96 |
  | v2.1.95 |
```

## Scenarios

- Declarative — WHAT not HOW
- One outcome per scenario
- Use domain language
- No incidental detail

## File Organization

```
features/
  <domain>/
    <feature>.feature
```

## Scope

- Features test user-facing behavior (the WHAT)
- Implementation edge cases belong in specs (the HOW)
- Ask: "would a user describe this scenario?" If no, it's a spec

## Anti-Patterns

- Creating new step definitions when the DSL covers it
- Creating World modules or `.rb` files unnecessarily
- Imperative scenarios with implementation details
- Testing multiple outcomes in one scenario
