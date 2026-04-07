---
argument-hint: [number of versions, default 10]
---

First, trigger the dude GHA to test the latest release:

```bash
latest=$(gh release list -R anthropics/claude-code --limit 1 --json tagName -q '.[].tagName')
gh workflow run dude.yml -R UKGEPIC/dude --ref cukes -f prompt="1 + 1" -f version="$latest" -f timeout=5
echo "Triggered smoke test for $latest"
```

Then show the current installed version:

```bash
claude --version
```

Then use /await to monitor the smoke test run in background. The check command:

```
gh run list --repo UKGEPIC/dude --branch cukes --limit 1 --json status -q '.[0].status' | grep -q completed
```

Once the run completes, check the result:

```bash
conclusion=$(gh run list --repo UKGEPIC/dude --branch cukes --limit 1 --json conclusion -q '.[0].conclusion')
run_id=$(gh run list --repo UKGEPIC/dude --branch cukes --limit 1 --json databaseId -q '.[0].databaseId')
echo "Smoke test: $conclusion (https://github.com/UKGEPIC/dude/actions/runs/$run_id)"
```

If it failed, get the error:

```bash
JOB_ID=$(gh api repos/UKGEPIC/dude/actions/runs/$run_id/jobs --jq '.jobs[0].id')
gh api repos/UKGEPIC/dude/actions/jobs/$JOB_ID/logs 2>&1 | grep -E "(Error|error|FAIL)" | head -5
```

Report the smoke test result clearly: version tested, pass/fail, and error if any.

Then fetch release notes from GitHub. Use $ARGUMENTS as the limit if provided, otherwise default to 10:

```bash
limit=${ARGUMENTS:-10}
for tag in $(gh release list -R anthropics/claude-code --limit "$limit" --json tagName -q '.[].tagName'); do echo "## $tag"; gh release view "$tag" -R anthropics/claude-code --json body -q '.body'; echo; done
```

Display the output as-is. Do not summarize or rewrite.
