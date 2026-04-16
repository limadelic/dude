# Alley-PR

## Why

- alley-oop: bot lobs the PR, you slam the merge
- can't merge your own PR (git rules)
- need at least 1 reviewer (company rules)
- GHA bot creates the PR, you review and merge

Delegate to a haiku subagent that runs `dude alley-pr` in the background to create a PR for the current branch.
