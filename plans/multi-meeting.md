# Multi-Agent Meeting Notes (2026-03-09)

Source: `meetings.vtt` — last 40 mins extracted, noise removed.

## TL;DR

No multi-agent code needed from us. BryteHub + SuiteX handles routing via intent classification. Register agents, train intents, done. SDK is NOT required for beta but likely mandatory for GA. Two blockers: consent flow and file upload not supported by SDK.

## How Agent Routing Works

1. Each agent is registered in BryteHub under SuiteX-Search
2. Each agent gets **intent classification** — "golden phrases" that trigger it
   - Example: "create a pool" → TalentPool agent, "find me a job" → AIVA
3. When user types in Bryte Assist, intent classifier picks the right agent automatically
4. Handoff between agents is automatic — no client code

> Nasib: "If I said I need a job...that intent is through Ava's agent, it'll know to just go to Ava's agent."

## Registration Steps (per agent)

1. Register agent in BryteHub (toggle to make available)
2. Raise feature flag request (GR) — one-time, agent-specific
3. Train intent classifier with golden phrases/examples
4. Set global tenant ID (null = all tenants) + agent name

Intent classification is agent-level, not page-level. Once registered, agent is available across all recruiting pages.

## AppContext / Session Flow

First interaction:
- Bryte/SuiteX calls your endpoint with **Accept Context header** containing:
  - `tenantId`, `userId`, `serviceCode` ("h:rec"), `deploymentIdentifier`, `environmentType`
- Endpoint validates tenant/user/product, returns session info
- Subsequent messages maintain same session

## Response Decoration

- **REST tool output** → fully decoratable (chips, tables, buttons, cards)
- **AI-generated text** → plain text only, cannot be interactive chips
- Limitation acknowledged — SDK team aware

## SDK Adoption Timeline

| Milestone | SDK Required? |
|-----------|--------------|
| Beta | No |
| GA (R1) | Likely yes — Didi confirmed SDK not required for R1 GA, but expectation is moving toward it |

> "SDK is not gonna be done for beta, but for GA... I have a feeling they're gonna want us to be on SDK."

## SDK Blockers (Recruiting-Specific)

### 1. Consent Flow
SDK assumes employee users — no consent mechanism for external candidates. Recruiting REQUIRES candidate consent (regulatory). Cannot move to SDK for GA without this.

> "If you guys haven't solved for this yet, then I can't really say in good conscience that we're gonna be able to move to SDK for even Georgia."

### 2. File Upload (Resume)
No upload capability in Bryte Assist MFE. Candidates need to upload resumes for job matching / skills extraction. SDK team aware, not prioritized.

## Recruiting Agent Ecosystem

| Agent | Status | Registered in Bryte? |
|-------|--------|---------------------|
| AIVA (ProPeopleCandidateAssistAgent) | In progress | Needs registration + intent training |
| Job Genius | Live | No — direct/raw access |
| Talent Pool Agent | Live | Yes (hidden SDK) |
| Interview Scorecard Agent | In progress | No — direct/raw access |

**Strategy**: Move all 4 to SuiteX, add intent classification, then move Bryte Assist MFE to global layout page (available on every recruiting page).

## Registration: Direct vs Routed

- **Direct (raw)**: Job Genius, Interview Scorecard — call agent endpoint directly, no BryteHub
- **Routed (via Bryte)**: AIVA, Talent Pool — registered in BryteHub, intent-classified, auto-routed

AIVA REQUIRES registration because it needs to be invoked from Bryte Assist via intent detection.

## Action Items

1. Nasib to share technical PRs for intent classifier registration
2. Nasib to share BryteHub configuration PRs
3. Raise consent flow gap in next Bryte GA call
4. Raise file upload gap with SDK team
5. Plan multi-agent strategy for all recruiting pages
6. Deepti to confirm plan for moving Bryte Assist to all pages

## Key Takeaway

The multi-agent story is a configuration problem, not a code problem. Register agents, train intents, let the platform route. Our work is making sure each agent works correctly when invoked — not building the routing.
