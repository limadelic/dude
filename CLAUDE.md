# The Big Lebowski Alley

This folder supervises three full-clone lanes running in parallel: **dude/** (main), **walter/** (lane 2), **donny/** (lane 3). Lanes are gitignored here and live as sibling directories.

## Supervision Rules

- **Never read files or logs directly.** Haiku subagents fetch, supervisor judges summaries only.
- **CLAUDE.local.md is source of truth:** three sections (dude, walter, donny), each with current branch + what it's doing. Update after every significant change.
- **Evidence over narrative.** Reports must paste diffs, command output, shas, pids—not claims alone.

## The Bowling Way

- **Main lane only pushes:** Dude (main lane, branch malko) is the only pusher to origin. Walter and Donny hand findings to Dude; Dude merges and ships.
- **Merge not rebase.** Lanes re-branch fresh from main after each merge to stay clean.
- **One tree, one writer.** Exactly one agent mutates a given lane at a time. Read-only analysts can run anywhere.
- **5-min kill rule.** No artifacts, no log growth, no run in flight for 5 minutes → kill and re-brief smaller. (Sanctioned waits like test timeouts are exempt.)
- **No worktrees.** Full clones only. Each lane has its own .git, _build, runtime—shared state is death.

## Brief Anatomy

Every lane brief must contain:

- **Lane dir + branch + node names**, stated explicitly. Agents drift to familiar names; anchor them in the brief.
- **Task as WHAT not HOW.** One visible outcome. "Fix that test" not "try adding a retry."
- **Hard constraints verbatim.** (Never push from side lanes. Never touch protected pids.)
- **Required evidence in report.** Pasted diffs, pasted command output, pids, shas. No narrative alone.
- **Detached-run pattern.** Anything long: nohup + log in scratchpad, report pid immediately, a later task reads the log.

## When to Bowl

- Split one wall into different attack strategies—lanes race, first proof wins.
- Pipeline: main lane lands the current change while a side lane pre-solves the NEXT wall.
- Shenanigans lane: high-churn, mechanical work (credo, lint, mass renames) gets its own lane so it never clogs features.
- DON'T bowl: single-file edits, anything needing one shared runtime, work faster to brief than to do.

## Dance Moves

- **Distinct agent names per lane.** Shared epmd/:global means same-name lanes corrupt each other's runs. Enforce in the brief. Check session-log cwd/names in reports.
- **Reap before you diagnose.** Stale beams/epmd from days ago poison live runs. ps + epmd -names clean-room check before any live conclusion.
- **Cheap read-only lanes.** Predictor agent maps the code path so run logs get read against a theory, not cold.

## Standing Orders

- Lanes are named Lebowski-style: Dude, Walter, Donny (Jesus reserved for endgame).
- Supervisors identify by lane name in all reports—pwd, branch, node names at the top; context stays traceable.
- No middle ground: delegation all the way down. If you find yourself reading logs or typing edits, the brief was too wide.
