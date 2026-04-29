# Alley-PR: Public/Generic Routing

## Problem
`/alley-pr` always triggers the UKGEPIC `dude.yml` GHA workflow to create PRs.
Non-UKGEPIC repos don't have that workflow, so it fails.

## Solution
Detect org from git remote. UKGEPIC -> workflow path (existing). Everything else -> simple `gh pr create`.

## Design
One class, two private paths. No new classes.

```ruby
def execute
  branch = current_branch
  guard_main_branch(branch)
  ukgepic? ? workflow_pr(branch) : simple_pr(branch)
end

def ukgepic?
  extract_org_from_remote == 'UKGEPIC'
end
```

### Simple PR path
1. `git push -u origin <branch>`
2. `gh pr create --fill` (uses commit messages for title/body)
3. Copy PR URL to clipboard
4. No skip-ci commit (not needed without bot workflow)

### Workflow PR path
Unchanged — current behavior.

## Shared
- `guard_main_branch`
- `copy_pr_to_clipboard`
- Push logic

## Changes

| File | What |
|------|------|
| `lib/dude/dudes/alley_pr.rb` | Add `ukgepic?`, `extract_org_from_remote`, `simple_pr` method. Refactor `execute` to route. |
| `spec/dudes/alley_pr_spec.rb` | Add context for non-UKGEPIC repos (simple path). Keep existing UKGEPIC tests. |
| `features/alley_pr/alley_pr.feature` | Add scenario for simple PR path. |

## Notes
- `extract_repo_from_remote` already exists (line 47-50), just need to split out org
- `--fill` keeps it simple — no Claude needed for title/body on public repos
- No skip-ci empty commit for simple path (no bot to loop)
