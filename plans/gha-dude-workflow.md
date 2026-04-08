# GHA Reusable Workflow: dude.yml

**Issue:** UKGEPIC/dude#152
**Status:** Discovery complete, workflow drafted

---

## Yellow Card: Problem

Need a reusable GitHub Actions workflow that runs Claude CLI directly — no GitHub orchestration layer. The existing `claude.yml` wraps the action, which handles GitHub-aware features (auto-detecting context, managing branches, posting reactions). But some callers don't need that complexity. They want minimal: install Claude, set env, run a prompt. The caller workflow owns GitHub context.

## Blue Card: What We Learned

**The action is NOT just a wrapper.** It's a GitHub event orchestrator that:
- Auto-detects workflow intent (PR review vs @claude mention vs custom automation)
- Manages GitHub state (branches, reactions, buffered comments, permissions)
- Handles security (scrubs secrets, validates triggers, checks write perms)
- Bidirectional Claude ↔ GitHub integration (Claude reads context, writes to GitHub)

**For a lighter workflow:** We don't need any of that. The caller handles GitHub plumbing themselves.

**Design principle:** Two tools, two jobs.
- `claude.yml` = GitHub + Claude orchestration (action-wrapped, full features)
- `dude.yml` = CLI execution only (caller owns GitHub flow)

## Green Card: What We Built

Created `/Users/maykel.suarez/.claude/.github/workflows/dude.yml`

**Minimal interface:**
```yaml
inputs:
  prompt (required):        Instructions for Claude
  version (default 2.1.87): Claude Code version
  cwd (optional):           Working directory relative to workspace
  timeout (default 30):     Job timeout in minutes
  claude_args (optional):   Additional CLI flags

secrets:
  LITELLM_KEY:             API key
```

**What it does:**
1. Checkout repo
2. Set npm registry to internal Jfrog
3. Install claude-code (specified version)
4. Run CLI: `claude <args> -- <prompt>`
5. Set env vars (ANTHROPIC_BASE_URL, CLAUDE_CODE_MODEL)

**No GitHub context extraction, no state management, no auto-detection.** Caller passes prompt as-is, workflow executes.

## Red Card: Open Questions / Future

- **Outputs:** Should we expose execution file path or other artifacts? (Current: just exit code)
- **Cwd handling:** Is `GITHUB_WORKSPACE` modification sufficient, or do we need path normalization?
- **Version pinning:** Should default version auto-update, or stay pinned for stability?

---

## Amigos Sign-Off

- **Team Lead:** Clarified scope — not a replacement, a lighter building block
- **Kent:** Questioned settings input — resolved via `claude_args` escape hatch
- **Dude:** Locked interface, drafted workflow

Ready for implementation / test.
