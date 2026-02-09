# Alley-PR

Create a PR via github-actions bot so the user can approve it themselves.

NEVER mention Checkmarx. We don't wait for it, we don't care about it, ignore it completely.

## Setup

Detect repo from git remote: `git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/'`
Store as `<REPO>` for all commands below.

## Steps

1. Push current branch to origin (with -u if needed)
2. Trigger dude workflow: `gh workflow run dude.yml --repo <REPO> --ref <branch-name> -f prompt="create PR for branch <branch-name> using gh pr create --label skip-ci"`
3. Get run ID: `gh run list --repo <REPO> --workflow=dude.yml --limit 1 --json databaseId -q '.[0].databaseId'`
4. Wait for workflow to complete: `~/.claude/skills/supervising/wait-until.sh 'test "$(gh run view <RUN_ID> --repo <REPO> --json status -q .status)" = "completed"' 30` with run_in_background: true
5. Find the created PR and copy URL to clipboard with pbcopy
6. Push empty commit with skip-ci: `git commit --allow-empty -m "[skip ci]" && git push`
7. Check what's blocking the PR: `gh pr view <PR#> --repo <REPO> --json reviewDecision,mergeStateStatus,statusCheckRollup -q '{review: .reviewDecision, state: .mergeStateStatus, pending: [.statusCheckRollup[]? | select(.state == "PENDING") | .name]}'`
8. Watch PR until mergeable: `~/.claude/skills/supervising/wait-while.sh 'test "$(gh pr view <PR#> --repo <REPO> --json mergeStateStatus -q .mergeStateStatus)" = "BLOCKED"' 30` with run_in_background: true
9. When ready, merge with `gh pr merge <PR#> --repo <REPO> --squash`
