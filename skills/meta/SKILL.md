---
name: meta
description: Use when creating or modifying any instruction file (skill, command, hook)
---

# Meta

## Template

```markdown
---
name:
description: Use when...
---

# Name

## What
[one paragraph max]

## How
[the instruction]

## Refs
[links if needed, else delete]
```

## Check

Before saving, verify:
- [ ] Frontmatter: name + description only
- [ ] Description starts with "Use when" or verb
- [ ] Max 3 sections after heading
- [ ] Each section under 25 lines
- [ ] Total under 50 lines
- [ ] No filler phrases ("This skill helps...", "In order to...")

Fail any check = cut until pass. Don't ask.

## Constraints

- Never create from blank — copy template first
- Never exceed limits — cut, don't negotiate
- Never explain what you're about to do — just do it
- No preamble, no meta-commentary
- One example max, only if essential
