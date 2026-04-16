# Alley-PR Discovery Plan

## Yellow (Story)
Extract the alley-pr skill from SKILL.md into the dude gem as a Ruby command.

## Blue (Rules)

- **Location**: `lib/dude/dudes/alley_pr.rb` — single operation class like `GitStageCommit`
- **Class**: `Dude::Dudes::AlleyPr` with `execute` method
- **CLI registration**: Add `alley_pr` command in `lib/dude/helpers/cli.rb`
- **Skill update**: SKILL.md becomes a one-liner calling `dude alley-pr`
- **Naming**: Keep "alley-pr" — it's the term users know
- **Main branch guard**: Refuse to run on main. Business rule, non-negotiable
- **Idempotent**: Always run full sequence. Let `gh pr create` and the workflow handle their own idempotency
- **Error on no PR**: If workflow completes but no PR found, error with run URL. Don't push skip-ci
- **Multiple PRs**: Pick latest open PR. Warn if count > 1
- **Existing helpers**: Use `Dude::Helpers::Wait` for polling, `Dude::Helpers::Gh` for gh commands
- **pbcopy**: macOS-only, fine for now

## Green (Examples)

### Happy Path
- **Given** a branch with commits ahead of main
- **When** `dude alley-pr` is run
- **Then** push branch, trigger dude.yml workflow, poll until complete via `Helpers::Wait`, find PR via `gh pr list --head <branch>`, copy URL to clipboard, push empty `[skip ci]` commit

### Branch already pushed
- **Given** the branch is already at origin
- **When** `dude alley-pr` is run
- **Then** push is a no-op, continues with workflow trigger

### Workflow fails
- **Given** the dude.yml workflow run fails (conclusion != success)
- **When** polling detects completion
- **Then** error with "Workflow failed" + run URL. Don't push skip-ci

### Workflow succeeds but no PR
- **Given** workflow completes successfully but `gh pr list --head <branch>` returns empty
- **When** checking for PR
- **Then** error with "No PR found" + run URL. Don't push skip-ci

### Multiple PRs for branch
- **Given** branch has multiple open PRs
- **When** finding PR
- **Then** take newest, warn user "Multiple PRs found, using newest"

### On main branch
- **Given** current branch is main
- **When** `dude alley-pr` is run
- **Then** refuse with error

### Running twice
- **Given** PR already exists from a prior run
- **When** `dude alley-pr` is run again
- **Then** full sequence runs. Workflow + gh pr create handle their own idempotency. Skip-ci commit pushed (allow-empty)

## Red (Questions — Resolved)

- **Await pattern?** Use `Helpers::Wait` inline polling. No background tasks
- **PR discovery?** `gh pr list --head <branch> --state open --json url -q '.[0].url'` via `Helpers::Gh`
- **SKILL.md invocation?** Calls `dude alley-pr` instead of inline shell
- **pbcopy?** macOS-only, acceptable for now
- **Idempotency?** Don't overthink. Run full sequence every time. Tools handle their own idempotency

## Dev Notes

- **Current SKILL.md**: `~/.claude/skills/alley-pr/SKILL.md` — this is what we're extracting
- **Feature file**: `~/.claude/code/features/alley_pr/alley_pr.feature` — 5 scenarios, @wip
- **Repo detection**: Current SKILL.md uses `git remote get-url origin | sed` to detect repo — carry this into Ruby
- **Workflow trigger**: Passes prompt with `gh pr create --label skip-ci` via `-f prompt=`
- **Helpers::Wait and Helpers::Gh**: May or may not exist yet — kent analyzes, kenny builds if needed
- **Checkmarx**: NEVER mention it. Ignore completely. Rule from SKILL.md

## Participants
- **Kent**: Grounded in code. Found `Helpers::Wait` and `Helpers::Gh`. Confirmed location and patterns
- **Liz**: Surfaced await unknowns, PR discovery gaps, error states, race conditions. Pushed until concrete
- **Dude**: Confirmed domain language, error handling rules, user expectations
