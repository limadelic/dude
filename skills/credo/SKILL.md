---
name: credo
description: Sweep credo violations to zero - census, fan out kennys, gate, repeat
---

# Credo

Lint defines done. The census is the plan. Zero is the exit.

## Zero supervisor context

Credo checks itself — the census IS the audit. The supervisor spends
NOTHING here beyond two summaries:

- Send ONE foreman subagent with this skill to run the whole loop.
  The foreman IS the supervisor of this skill: he runs census, spawns
  his own kennys (subagents can spawn subagents — use the Agent tool
  with haiku), gates, repeats, exits at zero.
- The foreman reports ONLY: start census, exit census, commit sha,
  test output pasted, config diff pasted. He will bullshit; expected.
- Then send cartman: re-run `mix lint` + `mix test` + `git diff main --
  .credo.exs` IN THE SAME DIR AND BRANCH the foreman names (venue
  mixups produce false busts), compare against the foreman's claims.
- Supervisor reads the foreman's summary and cartman's verdict. Never
  the census, never the diffs, never the files.
- On a multi-lane board, credo gets its own lane — it never touches the
  feature lane's tree or the supervisor's attention mid-feature.

## Foreman brief (copy into the spawn prompt)

- You own this skill end to end: read it, obey it, run the loop to zero
- Work ONLY in the named dir + branch; never push; commit at the gate
- FIRST action: `cd <dir> && pwd && git branch --show-current` — paste it
  in your report; if it doesn't match the brief, STOP and say so. A
  foreman once swept the wrong lane and rewrote a file mid-diagnosis;
  every subsequent command runs with the dir given absolute, never
  relying on inherited cwd
- Spawn haiku kennys with the Agent tool, one file each, background,
  briefs per Fan out; you gate, they never commit
- Before any `mix test`: `epmd -names` — if feature node names are
  registered a live run is in flight; wait on its pid with
  `lsof -p <pid> +r 10`, never kill it
- Report format: dir+branch, census before/after per round, final sha,
  pasted `mix lint` tail + `mix test` summary + `git diff main --
  .credo.exs` output. Anything not pasted didn't happen

YOU ONLY FIX WHAT CREDO DETECTS. NEVER FIX ANYTHING BY LOOKING AT IT.
NO EYEBALLING FILES, NO HAND-SPOTTED PROBLEMS, NO HUNCHES. IF A HUMAN
SEES A VIOLATION CREDO MISSES, THE CHECK IS BROKEN — TIGHTEN THE CHECK,
PROBE IT, RE-CENSUS, AND ONLY THEN FIX WHAT IT FLAGS.

## North Star

- These rules aren't perfect and may contradict each other.
- When rules fork, minimal code wins: the simplest, smallest code possible.
- Less code is ALWAYS the winner. Every decision resolves toward fewer lines.

## Detection First

- Credo is the only witness. You fix NOTHING credo doesn't flag.
- Someone points at a problem? Credo must corroborate — make the check
  detect it, show its output flagging the exact lines, THEN fix.
- No eye reviews as proof, no planted probes, no hand-fixing from a hunch.
- Zero violations with a lax check is a lie — when real problems pass,
  the bug is in the check. Tighten detection, re-census, then sweep.
- A rewritten check is guilty until probed: temp file with known-bad and
  known-allowed calls, credo must flag the bad and pass the allowed,
  `mv` the probe to /tmp. No probe pass, its zero means nothing.

## Config Audit

- BEFORE anything: `git diff main -- .credo.exs`. Any loosening on the
  branch (allowlist additions, threshold bumps, disabled checks) is a
  kenny dodging fixes — revert it, put the violations back in the census.
- AT EXIT: same diff again. Kennys are sneaky; a clean census bought by
  a loosened config is a lie. Config diff must be empty or tightening-only.
- Hard conflict (e.g. two same-arity imports)? Skip that file, report it.
  The config is never the fix.

## NEVER

- NEVER fix what credo doesn't flag — teach credo to detect it first
- NEVER touch thresholds, complexity 1 means zero branches, that's the point
- NEVER edit .credo.exs to make a violation disappear — allowlists and
  thresholds are not fixes; skip the file instead and say so
- NEVER let a kenny commit, the gate commits
- NEVER let a kenny near git checkout/restore/stash — one revert
  torched four teammates' fixes; forbid it in every brief
- NEVER do the edits yourself, you supervise
- NEVER `gh run watch`, poll `gh run view <id> --json status,conclusion`
- NEVER chase compile errors agents report mid-batch, the gate settles them
- NEVER rename and rewrite in one commit — `git mv` commit first, refactor
  commit second, or the PR shows pure additions and history is gone

## The Loop

### Census

- `mix lint`, group violations by file, sort descending
- That list IS the plan, top 5 files = next batch

### Fan out

- 5 kennys per batch, ONE file each, background always
- Brief: the exact `mix credo <file>` command, renames only, no wrappers,
  no commits, update call sites and `only:` import lists
- OTP and credo callbacks are allowlisted, kennys don't rename them
- Paired files both in a batch: each may report the other, never edit it

### Gate

- `mix compile --warnings-as-errors` + `mix test` + fresh census
- Green and smaller census, next batch
- Census at zero, exit

## Exit

- `mix format`, `mix lint` ZERO, commit, push
- Poll the CI run until green, green in CI is done, not before
