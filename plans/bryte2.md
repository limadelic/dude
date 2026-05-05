# Bryte 2.0 — Mementos

Durable facts only. No journey, no debate.

---

## The architecture (one sentence)

**One ADK Supervisor + N composable Skills, fronted by a BFF that routes per-intent to either 1.0 smart agents or the 2.0 supervisor.**

## The dates that matter

- **Gate 1b end-Apr 2026** — Bryte 2.0 live for uKrew
- **Gate 2 mid-May 2026** — Skills Platform v1 + first 5–10 external customers
- **Gate 3 Aug 2026** — Bryte 1.0 EOL. 53 prod agents migrate (25→Skills, 14→hybrid, 14→drop).

Source: Confluence "Bryte 2.0 Modernization" (id 1128693890).

## The two endpoints in production

The BFF (`suitex-search-conversation-assistant`) holds both clients, always instantiated. Routing is **per-intent**, decided by the action type in intent JSON.

| Path | Trigger | Env var | Endpoints |
|---|---|---|---|
| **1.0** | `CreateAgentSessionActionData` / `SendAgentMessageActionData` | `AI_HOST` | `POST /agents/api/v1/agents/by_name/{name}/sessions` + `/sessions/{id}/messages` (also `/api/v2/...`) |
| **2.0** | `CreateAdkSessionActionData` / `SendAdkMessageActionData` | `ADK_AGENT_URL` | `POST /api/session` + `POST /api/chat` (SSE) + `POST /api/confirm` |

Feature flag: `config-bryte-assist-adk-agent-enabled` (LaunchDarkly).

**Migration is intent-by-intent. No global toggle.**

## The federated 2.0 repo ecosystem

Smith has no equivalent. 2.0 is decentralized.

| Repo | Role |
|---|---|
| `workspace-bryte2-0-all-workstreams` | Meta-coordination |
| `workspace-bryte-supervisor-agent` | Supervisor team's SDLC |
| `workspace-bryte-foundational-skills` | Foundational skills team |
| `workspace-bryte-conversational-experience` | Conv-experience team |
| `bryte-supervisor-agent` | Supervisor runtime (cloned at `ds/bryte-supervisor`) |
| `unified-skills-specs` | Skills schema + governance |
| `ds-agent-config` | Central agent/intent config registry (2.0) |
| `ds-terraform-skills-pipeline` | Skills provisioning (the smith-cousin for 2.0) |
| `mcp-general-inquiry` | MCP HR data server |

## The minimal 2.0 agent — `SKILL.md`

Skills SDK prototype (PR #58 in `workspace-bryte-supervisor-agent`). 74 skills already converted. Loader = filesystem scan + YAML frontmatter parse, baked into supervisor docker at build.

```markdown
---
name: groot
description: Friendly greeter
version: 1.0.0
tools: []
---
# Greeeet
You are Greeeet. Introduce yourself, ask the user's name, greet warmly.
```

**Status: prototype, not merged to supervisor main.** Today on main: still requires ~20 lines of Python `SkillRegistration` per skill.

## Pure ADK YAML (upstream Google) — also works

```yaml
name: groot
model: gemini-flash-latest
instruction: "You are Greeeet..."
```

Run: `adk run`. Sub-agents via `sub_agents: [{ config_path: foo.yaml }]`. Marked `@experimental` in ADK 1.26+. Loader: `google.adk.agents.config_agent_utils.from_config()`.

## Today's 1.0 is also declarative

`groot.json` with `orchestrator.prompt.instructions: ["…markdown…"]`. 121 agents in `ds/agents` use this. **No Python required for team-owned agents** — that scariness only applies to in-process supervisor skills.

## API contracts confirmed (source-of-truth)

- `ds/swagger/smart-agents-model.json` (OpenAPI 3.1.0) — v1 + minimal v2 endpoints. **No supervisor/ADK spec here.**
- `ds/postman/gateway-collection/...` — v1 endpoints **alive, not deprecated**. No `agents/api/v2` namespace. No `supervisor/api`. **But `skills/api/v2` exists with 9 endpoints** (career-pathways, feedback-summary, goal-summary, …) — separate skills service, worth a deeper look.
- `ds/bryte-bff/openapi-spec.json` — BFF's own spec, updated 2026-04-30.

## Smith ↔ Bryte 2.0 — the gap

Smith hits `agents/by_name/{name}/sessions` to test a specific agent. The supervisor's `/api/session` + `/api/chat` are generic — **no by-name targeting of a specific skill.**

Three possibilities (need confirmation from Bryte architecture owner):
1. Supervisor adds a by-name endpoint
2. Smith pivots to per-skill direct URLs
3. A new "skills runtime" service is planned

## Useful internal links

- Confluence: `https://engconf.int.kronos.com/spaces/AI/pages/1128693890/Bryte+2.0+Modernization`
- Skills SDK PR: `gh pr view 58 -R UKGEPIC/workspace-bryte-supervisor-agent`
- Archetypes PR (behavior packs): `gh pr view 60 -R UKGEPIC/workspace-bryte-supervisor-agent`
- Supervisor README: `ds/bryte-supervisor/README.md`
- BFF agent clients: `ds/bryte-bff/src/...AgentsClient.kt` + `AdkClient.kt`
- BFF routing: `ds/bryte-bff/src/...ChainActions.kt`
- BFF env: `SharedContext.kt` (`AI_HOST`, `ADK_AGENT_URL`)

## Skills — three-layer architecture (from Confluence)

Source pages: 1128713791 (dev guide), 1128713765 (migration), 1142912182 (what's new).

| Layer | Token budget | Loaded when |
|-------|-------------|-------------|
| L1 metadata | ~100 tokens | Always (all skills) |
| L2 instructions | ~5,000 tokens | Skill activated |
| L3 resources | Unlimited | On-demand only |

Supervisor scans `bryte-supervisor-agent/multi_tool_agent/skills/*/*/SKILL.md` at startup. `BryteSkillLoader` extracts L1. `SkillToolset` exposes `list_skills()`, `load_skill(name)`, `load_skill_resource(name, path)`.

**Minimal skill (no Python, no tools):**
```
skills/greeting/groot/SKILL.md
```
```markdown
---
name: groot
version: 1.0.0
description: Friendly greeting agent
author: you@ukg.com
tags: [greeting]
---
# GROOT
You are GROOT. Greet the user warmly and offer to help.
```

## Local boot recipe (verified 2026-05-01)

The supervisor has **no public Cloud Run URL**. Deployed only to Vertex AI Agent Engine `3692607547304312832` in `d-ulti-ml-ds-dev-9561 / us-central1` — accessed via SDK, not HTTP. **Local-first is the only practical path for Smith → 2.0 testing right now.**

### Boot
```bash
cd ds/bryte-supervisor
just setup           # one-time: uv sync, .env scaffold, npm install
just run --no-auth   # supervisor on :8000, LOCAL_DEV=true
```

`--no-auth` (`Justfile:59-74`) sets `LOCAL_DEV=true` which:
- Skips Trellis token validation (`src/common/auth/dependency.py:14-19`)
- Makes `agent_framework_context` optional in request bodies (`src/services/sessions/service.py:49-50`)
- Skips Model Armor sanitization at runtime

### Minimal `.env` (5 vars)
| Var | Notes |
|---|---|
| `GOOGLE_CLOUD_PROJECT` | needed for Vertex AI LLM calls |
| `GOOGLE_CLOUD_LOCATION` | e.g. `us-central1` |
| `LAUNCHDARKLY_SDK_KEY` | dummy OK with `SECURITY_ENABLED=false` |
| `MCP_GENERAL_INQUIRY_URL` | dummy OK |
| `MODEL_ARMOR_TEMPLATE` + `_LOCATION` | optional under `LOCAL_DEV=true` |

`ENABLE_MEMORY_BANK=false` (default) → in-memory sessions, no Vertex memory required.

### Health check
```bash
curl http://localhost:8000/actuator/health
curl http://localhost:8000/api/backend   # → {"backend":"local"}
```

### Minimal session create
```bash
curl -X POST http://localhost:8000/api/session \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"test"}'
# → {"id":"<uuid>", ...}
```
Schema: `ApiSessionRequest` (`src/api/core/sessions/schemas.py:8-12`) — only `user_id` required.

### Minimal chat
```bash
curl -N -X POST http://localhost:8000/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"session_id":"<uuid>","user_id":"test","message":"hello"}'
# → SSE stream
```
Schema: `ApiChatRequest` (`schemas.py:15-20`) — `session_id`, `user_id`, `message` required.

### Smith wiring
`lib/ds/adk/api.rb` already targets these endpoints. Default host `http://localhost:8000` (override via `ADK_HOST`). No context, no auth, no token injection needed.

### Gotchas (verified end-to-end on 2026-05-01)
- LaunchDarkly + Model Armor init at startup (`src/main.py:44-49`) — needs at least dummy env vars
- UI proxy injects `ds_auth_token` from `/api/mcp-token` — direct curl/Ruby calls don't need it under `--no-auth`
- `uv` may not be on PATH — install via `brew install uv` first
- **Corporate cert blocks `uv sync`** — must set `SSL_CERT_FILE=~/.claude/ukg.pem` so uv can download Python through UKG's SSL interception
- **Required `.env` fields beyond the minimum 5**: `AUTH_AUDIENCE=dummy-audience`, `TROX_ENVIRONMENT=sbx`, `MODEL_ARMOR_TEMPLATE` + `MODEL_ARMOR_LOCATION` (any value), `LOCAL_DEV=true`
- Port 8000 may be busy → run on `:8001` and pass `ADK_HOST=http://localhost:8001` to Smith
- LaunchDarkly SDK warns about SSL with dummy key — harmless, supervisor still serves traffic

### Proven recipe
```bash
brew install uv
cd ds/bryte-supervisor
SSL_CERT_FILE=~/.claude/ukg.pem uv sync --group dev
.venv/bin/uvicorn src.main:app --host 0.0.0.0 --port 8001 &
cd /Users/maykel.suarez/dev/self/smith
ADK_HOST=http://localhost:8001 ruby groot/test/groot_supervisor_test.rb
# → 1 run, 2 assertions, 0 failures, 0 errors ✓
```

## Team-endorsed test path (from #bryte2-collab Slack 2026-05-01)

Marc Khoury confirmed in Marvin Dore's thread:

1. **Local supervisor** — `ds/bryte-supervisor` repo, run with `just run --no-auth`
2. **Local Bryte frontend** — also in the supervisor repo (`ds/bryte-supervisor/ui/`), serves the chat UI on `:3034`
3. **Requestly browser extension** — for injecting real dev-environment auth/context (tenant, user, tokens) into requests when testing skills that need real data
4. Requestly setup docs not in Confluence yet — Marc will add

**Implications for Smith:**
- Greeting test (no context required) → current path works as-is, no Requestly needed
- Future tests against skills that need real auth/tenant → either set context manually in our request body or run them through the UI with Requestly
- The local-first approach is officially endorsed; no public Cloud Run URL is coming soon

Channel: `#bryte2-collab` (`C0B143P0XHQ`) — Jen Baker created 2026-05-01, 19 members.

## Open questions for the Bryte team

1. Is there a planned `by_name` (or equivalent targeted-agent) endpoint on the supervisor?
2. When does Skills SDK PR #58 merge into supervisor main?
3. Will `ds-terraform-skills-pipeline` accept `SKILL.md` from team workspaces, or only the supervisor's own skills?
4. Will smith get a 2.0 successor, or do teams move to per-team workspace repos?

## Submodules (current as of 2026-04-30)

| Path | Repo |
|---|---|
| `ds/agents` | `ds-terraform-agents-pipeline` |
| `ds/api` | `ds-service-smart-agents-model` |
| `ds/sdk` | `ds-library-agent-sdk` |
| `ds/postman` | `ds-tools-postman-collections` |
| `ds/bryte-sdk` | `ukg-bryte-assist-sdk` |
| `ds/bryte-web` | `suitex-search-web` (MFE chat) |
| `ds/bryte-bff` | `suitex-search-conversation-assistant` (BFF — routes per-intent) |
| `ds/brytehub` | `suitex-ez-agents` (admin: registry, flags, dashboards) |
| `ds/bryte-supervisor` | `bryte-supervisor-agent` (2.0 ADK supervisor) |
