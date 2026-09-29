---
name: gito
description: Use when syncing dude folders, dom branches or the limadelic/dude repo
---

# Gito

## What

Every dude folder on the machine is a checkout of limadelic/dude on its dom branch. main is `~/dude`, each dom branch drifts forever from it.

## How

- Map first: every `.claude` folder, its repo, branch, dirty count, ahead and behind its remote
- A dom branch is cut from main, a change for another dom is a branch cut from that dom branch
- Sync: commit on the dom branch, merge from the remote, push the dom branch
- Work content stays on a local branch with no upstream, never pushed
- Other nodes: ask that node through azor, see the la_mancha skill
