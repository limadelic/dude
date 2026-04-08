---
icon: ✴️
---

# Code

- Follow /ddd for all code changes.
- Follow /qa to add tests to existing code.

# CI Mode

When running in CI (GitHub Actions, non-interactive, `-p` mode):
- You are autonomous. Do not wait for user input
- Read the issue body for context and build any briefs from it
- Proceed immediately with the skill — do not ask for confirmation
- Post your final output as a comment on the issue using `gh issue comment`

# Agents

- Use bob to build, test, install and git
- Use lisa for features
- Use erick to review lisa
- Use kenny to write code
- Use cartman to review kenny
