# Sub Dudes

## What

A sub is a private dude belonging to a pub. Same messaging, same verbs, same skills — the only difference is visibility: public vs private.

- `/pub` = register as a public dude (visible to everyone)
- `/sub` = register as a private dude (visible only to your parent pub)

## Why

- Anthropic Agent Teams can't do this — same directory, same CLAUDE.md, same skills for all
- We fight with path gymnastics when kenny/bob do code work from `~/.claude`
- Each sub needs its own `.claude/` context (CLAUDE.md, skills, settings, MCPs)

## What makes a folder a Pub

A pub is a folder registered in the global pub (`~/.claude/dudes/`). That's it. The global pub is the source of truth for all pub registrations.

## The Pattern

```
pub-dir/
  dudes/          ← public registry (pubs register here)
  dudes/dudes/    ← private registry (subs register here)
```

Examples:
```
~/.claude/                        ← global pub (always exists)
  dudes/                          ← rec, ops, etc register here
  dudes/dudes/                    ← kenny registers here (dude's sub)

~/dev/rec/main/                   ← pub "rec" (registered in ~/.claude/dudes/)
  dudes/dudes/                    ← backend, frontend register here
  Product/                        ← backend's cwd
  Product/Presentation/           ← frontend's cwd
```

## /sub

- `/sub kenny` → walks up directory tree → checks each folder against `~/.claude/dudes/` → first match is the parent pub → registers in that pub's `dudes/dudes/`
- If no pub found walking up, you end up at `~/.claude` — the global pub, always there
- No recursion for now — one level of sub. Fractal is there for later

## Naming

- Underscore `_` = namespace separator
- `dude_kenny` = kenny is a sub of dude
- `rec_frontend` = frontend is a sub of rec
- `rec_backend` = backend is a sub of rec (even though frontend is inside backend's folder tree)

## Communication

- Same verbs: `tell`, `ask`, `watch`, `finish`
- Same skills: `/tell dude_kenny "run specs"`
- No new primitives

## Not Anthropic Agent Teams

| | Agent Teams | Sub Dudes |
|---|---|---|
| Directory | Same for all | Each sub has its own |
| .claude/ context | Shared | Independent per sub |
| Skills/MCPs | Same for all | Tailored per sub |
| Identity | Dynamic, ephemeral | Folder-based, static |
| Coordination | Shared task list | Pub/sub messaging |
| Scope | Same repo | Any subfolder |
| Cross-session | No | Yes (inherits from Pub) |

## First Sub

- Name: `kenny` (the coding sub)
- Directory: `~/.claude/code/`
- Purpose: gem work (specs, code, install) — own CLAUDE.md, own skills
- Parent Pub: `dude` (this session, `~/.claude/`)
