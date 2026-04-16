# Alley-PR Feature Tasks

## Overview
Extract the alley-pr skill into a Ruby command in the dude gem. Pattern: single operation class (like GitStageCommit) + CLI registration.

## Facts
- Helpers exist: `Dude::Helpers::Wait` and `Dude::Helpers::Gh` ✓
- CLI registration: `lib/dude/helpers/cli.rb` has Thor subcommands pattern
- Testing: RSpec with RR mocking, backtick stubbing in feature steps
- Feature file: `features/alley_pr/alley_pr.feature` (5 scenarios, @wip)

## Tasks

### Task 1: Implement AlleyPr class
**File**: `lib/dude/dudes/alley_pr.rb`

Create `Dude::Dudes::AlleyPr` with:
- `initialize()` — no args, uses git/gh commands
- `execute()` method with flow:
  1. Guard: fail if on main branch
  2. Push branch with -u if needed
  3. Trigger dude workflow: `gh workflow run dude.yml --ref <branch>`
  4. Poll for completion (use Wait helper)
  5. Check conclusion (failure = error with run URL)
  6. Query PRs: `gh pr list --head <branch> --json url`
  7. Handle: no PRs (error), multiple (warn + pick latest), one (return URL)
  8. Final commit: empty commit with skip-ci

Uses:
- `Helpers::Gh.create.run(cmd)` for shell
- `Helpers::Wait.new(timeout: 60).until { ... }`
- `system()` for git commands (matching GitStageCommit pattern)
- Backtick for git current branch detection

### Task 2: Register CLI command
**File**: `lib/dude/helpers/cli.rb`

Add to `Dude::Helpers::Cli`:
```ruby
desc "alley-pr", "Create PR for current branch"
def alley_pr
  require_relative '../dudes/alley_pr'
  Dude::Dudes::AlleyPr.new.execute
  puts "Done"
end
```

Pattern: follow `tcr` command (line 106-111).

### Task 3: Write RSpec spec
**File**: `spec/dudes/alley_pr_spec.rb`

Test with RR mocks:
- Main branch guard (fail + error message)
- Happy path: push → trigger → poll → find PR → commit
- Workflow fails: error with run URL
- No PR found: error with run URL
- Multiple PRs: picks latest, warns

Mock system(), backticks, Wait, Gh.

### Task 4: Verify Gherkin scenarios pass
**File**: `features/alley_pr/alley_pr.feature`

5 scenarios already written:
1. ✓ Refuses to run on main
2. ✓ Happy path
3. ✓ Workflow fails
4. ✓ Workflow succeeds but no PR
5. ✓ Multiple PRs

Use existing `dudes_steps.rb` (stub backticks, capture_stdout, verify_table).
Remove @wip tag when passing.

### Task 5: Update SKILL.md
**File**: `.claude/skills/alley-pr/SKILL.md`

Replace implementation steps with:
```
dude alley-pr
```

Keep description. This is now just a wrapper calling the gem command.

## Definition of Done
- All 5 Gherkin scenarios pass
- AlleyPr class fully tested in RSpec
- CLI command registered and callable
- No @wip tag on feature
- SKILL.md updated
