# Alley-PR

Use to create pull requests that the user can approve. If you skip this the PR would need to be cancelled.

NEVER mention Checkmarx. We don't wait for it, we don't care about it, ignore it completely.

## Setup

Detect repo from git remote: `git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/'`
Store as `<REPO>` for all steps below.

## Steps

- Push current branch to origin (with -u if needed)
- Trigger dude workflow: `gh workflow run dude.yml --repo <REPO> --ref <branch-name> -f prompt="create PR for branch <branch-name> using gh pr create --label skip-ci"`
- Get run ID: `gh run list --repo <REPO> --workflow=dude.yml --limit 1 --json databaseId -q '.[0].databaseId'`
- Use await skill (wait-until): `test "$(gh run view <RUN_ID> --repo <REPO> --json status -q .status)" = "completed"` with run_in_background: true
- Find the created PR and copy URL to clipboard with pbcopy
- Push empty commit with skip-ci: `git commit --allow-empty -m "[skip ci]" && git push`
