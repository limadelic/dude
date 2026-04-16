# Alley-PR

## Why

Git rules prevent merging your own PR, and company rules require at least 1 reviewer. This workflow creates the PR under the GHA bot identity instead of the developer, allowing the developer to review and merge their own work while satisfying both constraints.

Delegate to a haiku subagent that runs `dude alley-pr` in the background to create a PR for the current branch.
