---
name: gito
description: Use when syncing .claude folders, dom branches or the dude repos
---
# Gito

## Map

| Dom | Folder | Remote | Branches | Visibility |
|---|---|---|---|---|
| dude | ~/.claude (~/dude is a symlink) | limadelic/dude | main, wip | public |
| quijote | ~/dev/.claude | msuarz/quijote | main, wip | private, msuarz only |
| sancho | ~/dev/qxt (.claude inside) | msuarz/sancho | sancho | private, msuarz only |
| elita | ~/dev/self/elita | limadelic/dude | elita | public |

## Rules

- dude: all work on wip, PR wip -> main, merge only when mike says. After a merge, cut a clean wip and open a new PR.
- elita: cut from main, never merges back. All work on elita_wip, elita_wip merges into elita. PRs are elita_wip -> elita.
- sancho: in ~/dev/qxt the remote `dude` is fetch only, pushes are disabled.
- Public dude has no work content and no node content. Work goes to sancho, node and mesh content goes to quijote.
- Nobody outside sancho reaches the sancho node. Talk to @sancho.
- Leave the nested work repos in ~/dev/qxt alone (ops/rec, rec/app, rec/ppl).

## How

- Map first: every .claude folder, its remote, branch, dirty count, ahead and behind.
- Always use `git -C <folder>`. After a remote change, check `remote -v` in every folder.
- Commit on the dom branch, merge from the remote, push the dom branch.
- Move files with mv, never rm. Back up to /tmp first.
