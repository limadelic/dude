# News — Example Map

## Yellow (Story)

Convert /news bash logic into the dude gem CLI. The slash command becomes a thin wrapper that delegates to `dude news`.

**Issue**: UKGEPIC/dude#142

## Blue (Rules)

1. Gem triggers `dude.yml` GHA workflow with latest CC release version and prompt "1 + 1" (baked in)
2. Gem returns structured result: `{run_id, workflow, version, status, conclusion}`
3. Gem fetches releases from anthropics/claude-code (default 5, configurable via `--limit N`)
4. Gem reports installed vs latest CC version — no inference, just facts
5. Skill handles orchestration: /await for polling GHA completion, formatting output
6. Smoke test pass = GHA conclusion=="success"
7. Concurrent runs handled by GHA queueing — no special gem logic
8. Workflow identity (`dude.yml`, repo, branch) lives in the gem, not the skill

## Green (Examples)

**Happy path — smoke test passes**
Given the user runs `dude news`
When the GHA workflow completes with conclusion=="success"
Then show installed vs latest version, "Smoke test: success", and last 5 release notes

**Custom limit**
Given the user runs `dude news --limit 3`
When release notes are fetched
Then show only the last 3 releases

**Smoke test fails**
Given the GHA workflow completes with conclusion=="failure"
When dude news reports the result
Then show "Smoke test: failure" with a link to the run logs

**Version reporting**
Given installed CC is 2.1.87 and latest is 2.1.96
When dude news runs
Then show "Installed: 2.1.87, Latest: 2.1.96" at the top — user decides if they update

## Red (Questions)

None — all resolved during session.

## Glossary

- **smoke test**: quick compatibility check — run "1 + 1" against latest CC release via GHA
- **release**: a Claude Code version from anthropics/claude-code
- **news**: aggregated release notes + smoke test result — "what changed upstream and does dude still work?"
