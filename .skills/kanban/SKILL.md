---
name: kanban
description: Use when working with boards, issues, kanban, JIRA, or project tracking
---

# Kanban

## What

Manage issues and boards across three systems: UKG (work), Limadelic (personal), and JIRA.

## How

### GitHub Boards

| Org       | Repo           | Dir             | Board                                                | Token             |
|-----------|----------------|-----------------|------------------------------------------------------|-------------------|
| UKG       | UKGEPIC/dude   | ~/dude          | https://github.com/orgs/UKGEPIC/projects/156/views/1 |                   |
| Limadelic | limadelic/dude | ~/dev/self/dude | https://github.com/orgs/limadelic/projects/1         | $GITHUB_LIMADELIC |

- use the `dude` CLI. If unsure, run `dude -h`
- create issues in the dude repo, not the current working repo
- add issues to the board and set status to TO-DUDE

### JIRA

- board: https://engjira.int.kronos.com/secure/RapidBoard.jspa?rapidView=3017
- ACs live in customfield_14400. ALWAYS fetch with `fields: "*all"` and read that field
