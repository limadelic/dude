# GHA Workflow — Discovery Plan

Issue: UKGEPIC/dude#152

## Yellow (Story)

Create `dude.yml` — a reusable `workflow_call` workflow that runs `claude` CLI directly on a GHA runner. Alternative to `claude.yml` which wraps `anthropics/claude-code-action@v1`. Minimal: install claude-code, set env, run with a prompt.

## Blue (Rules)

1. `dude.yml` is an alternative, NOT a replacement for `claude.yml`
2. Caller owns GitHub context (reactions, comments, trigger detection, branch management)
3. `dude.yml` only installs and runs — it's a lower-level building block
4. Env vars are hardcoded in the workflow, not passed as inputs or settings files
5. No action wrapper, no bun, no deps hack

## Green (Examples)

### Happy path: caller triggers dude.yml with a prompt
- A trigger workflow (e.g. coolban.yml) detects a GitHub event, adds a reaction, builds a prompt string from the issue/comment context, and calls dude.yml with `prompt: "Review this PR and suggest improvements"`
- dude.yml checks out the repo, installs claude-code 2.1.87, sets all env vars, runs `claude "Review this PR and suggest improvements" --dangerously-skip-permissions`
- Claude reads the repo, does its work, exits 0
- The caller workflow takes Claude's output and posts it as a GitHub comment

### Subdirectory: caller passes cwd
- Caller calls dude.yml with `prompt: "Run the tests"`, `cwd: "code"`
- dude.yml checks out the repo, installs claude, runs claude from the `code/` subdirectory
- Claude sees CLAUDE.md, settings, and skills from `code/` — auto-discovery works

### Custom args: caller passes claude_args
- Caller calls dude.yml with `prompt: "Analyze this"`, `claude_args: "--json"`
- dude.yml appends `--json` to the CLI call
- Claude outputs JSON instead of plain text

### Version pin: caller overrides version
- Caller calls dude.yml with `version: "2.2.0"`
- dude.yml installs that specific version instead of the default 2.1.87

### Timeout: long-running job
- Caller calls dude.yml with `timeout: 60`
- GHA job times out at 60 minutes instead of the default 30

### Failure: claude exits non-zero
- Claude encounters an error and exits 1
- The GHA step fails, the job fails
- Caller workflow can use `if: failure()` to handle it (post error comment, etc.)

### Env vars are not configurable
- dude.yml always uses the LiteLLM proxy, opus model, haiku subagent
- Caller cannot override these — they're baked into the workflow
- If a different model is needed in the future, we add an input then

## Red (Questions)

- ~Should model be an input?~ No — hardcode, change later if needed (Kent)
- ~Should settings be an input?~ No — env vars handle config, claude_args is the escape hatch (Kent + Dude)
- Liz was unreachable during session — her ignorance-hunting perspective is missing

## Interface (Converged)

```yaml
inputs:
  prompt:
    type: string
    required: true
  version:
    type: string
    required: false
    default: '2.1.87'
  cwd:
    type: string
    required: false
  timeout:
    type: number
    required: false
    default: 30
  claude_args:
    type: string
    required: false
    default: ''

secrets:
  LITELLM_KEY:
    required: true

env (hardcoded):
  ANTHROPIC_BASE_URL: https://sdlc-llm.ukg.int
  ANTHROPIC_AUTH_TOKEN: ${{ secrets.LITELLM_KEY }}
  ANTHROPIC_MODEL: opus
  ANTHROPIC_DEFAULT_HAIKU_MODEL: claude-haiku-4-5
  ANTHROPIC_DEFAULT_OPUS_MODEL: claude-opus-4-6
  ANTHROPIC_DEFAULT_SONNET_MODEL: claude-sonnet-4-6
  CLAUDE_CODE_SUBAGENT_MODEL: haiku
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: '0'
  CLAUDE_CODE_ENABLE_TELEMETRY: '1'
  CLAUDE_CODE_USE_VERTEX: '0'
```

## Steps (Minimal)

1. Checkout
2. npm config set registry (internal Artifactory)
3. npm install -g @anthropic-ai/claude-code@version
4. cd to cwd if provided
5. Run: `claude "$prompt" $claude_args`

## Participants

- Kent: feasibility, interface design, env var analysis
- Dude: domain, naming, scope clarification
- Liz: absent (spawn/team registration issue)
