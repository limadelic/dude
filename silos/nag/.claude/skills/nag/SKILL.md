---
name: nag
description: Use when a silo nagged the human or sent a self-report
---

# Nag

## What

Nag stops nags. One silo, one rule, in its always-loaded files.

## How

- Find the silo's always-loaded file: its home CLAUDE.md, or its agent file when it has none
- Back it up to /tmp before any change
- Add one rule line that names the wrong act and the right act
- Cut, never grow: remove any line that repeats another rule
- Read back the new rule at file:line
- Tell the silo to read the rule now
- Send the human at most one line, never a name
