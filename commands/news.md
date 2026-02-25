---
argument-hint: [number of versions, default 5]
---

Run this bash command to get Claude Code release notes from GitHub, replacing $ARGUMENTS with the number provided (default 5 if none given):

```bash
for tag in $(gh release list -R anthropics/claude-code --limit $ARGUMENTS --json tagName -q '.[].tagName'); do echo "## $tag"; gh release view "$tag" -R anthropics/claude-code --json body -q '.body'; echo; done
```

Display the output as-is. Do not summarize or rewrite.
