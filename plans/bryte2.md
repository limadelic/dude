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
