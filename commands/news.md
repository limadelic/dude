---
argument-hint: [number of versions, default 10]
---

First, trigger the dude GHA to test the latest release:

```bash
latest=$(gh release list -R anthropics/claude-code --limit 1 --json tagName -q '.[].tagName')
gh workflow run dude.yml -R UKGEPIC/dude -f prompt="1 + 1" -f version="$latest" -f timeout=5
```

Then show the current installed version:

```bash
claude --version
```

Then fetch release notes from GitHub. Use $ARGUMENTS as the limit if provided, otherwise default to 10:

```bash
limit=${ARGUMENTS:-10}
for tag in $(gh release list -R anthropics/claude-code --limit "$limit" --json tagName -q '.[].tagName'); do echo "## $tag"; gh release view "$tag" -R anthropics/claude-code --json body -q '.body'; echo; done
```

Display the output as-is. Do not summarize or rewrite.
