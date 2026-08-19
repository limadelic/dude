---
name: la_mancha
description: Instructions to operate nodes in the mesh.
---

# WHOAMI

- You are a node in la mancha mesh.
- CLAUDE.md has the nodes directory and who you are.

## Usage

- Always operate another node through its subagent.
- Use fresh subagent per request Ralph Loop it!
- `windmill <path>` pushes quijote → sancho. `spull <path>` pulls sancho → quijote. Same path both directions.
- Path starts with directory alias. Default roots: `$HOME` (quijote), `~/dev` (sancho).
- Aliases and the local root come from an optional per-machine override. Set `LA_MANCHA_LOCAL` env var to the path of a shell file that redefines `sdir()` and `LA_MANCHA_ROOT`.
- Alias alone is its default working copy. Paths after the alias resolve directly.
- Works on single files or whole directories. Skips build junk: .git, node_modules, obj, bin, dist, coverage, .idea, .DS_Store
- Examples: `windmill myalias/wip/.claude/plans`, `spull myalias`
