# Multi-Agents

## Investigation

### 1. MAS (DS SDK Supervisor Pattern)

- Supervisor pattern via LangGraph — supervisor delegates to team members via handoff tools
- **Verdict:** Out of scope. Untested in prod, we're not guinea-pigging their framework.

### 2. IntentClassificationAgent (BryteHub)

- Single gateway agent that classifies user intent via Intent-Detection-Tool (REST)
- Confidence >= 8 → routes via RouteToAgent client tool to target agent
- Key file: `ds/agents/resources/dev/us-east4/dev-dev/SuiteX-Search/agents/IntentClassificationAgent.json`
- **Verdict:** Overkill for our case. Intent classification is for 10+ agents. We have 2.

### 3. RouteToAgent — How It Actually Works

- RouteToAgent is a **ClientTool** — calls raise `ClientToolInterruptError`
- API returns **202 ACCEPTED** with `WAITING_FOR_TOOL_RESULT` status
- **Client orchestrates the round-trip:**
  1. AIVA calls RouteToAgent → session pauses (not killed)
  2. Client creates new session with target agent, runs it
  3. Target agent finishes → client calls `POST /sessions/{ava_session_id}/actions/tool-result` with result
  4. AIVA's session resumes — result comes back as ToolMessage in her graph
- AIVA's session stays alive the whole time — she gets the response and keeps going
- Enigma does NOT need RouteToAgent back — client handles the return

## AIVA (ProPeopleCandidateAssistAgent)

- Config: `ds/agents/resources/dev/us-east4/dev-dev/NREC/agents/ProPeopleCandidateAssistAgent.json`
- Model: gemini-2.5-flash
- Suite: ProSuite / ProPeople / Talent Acquisition / Recruiting
- 4 REST tools: SKILLS_JOBMATCH, SUBSCRIBE_JOBALERT, QUICK_APPLY, GET_OPP
- No RouteToAgent yet — no client tools at all
- 32 instructions, state machine: DISCOVERY → SKILLS_SEARCH / SUBSCRIBE_FLOW / APPLY_FLOW
- Deployed across 9 envs

## Enigma (ProPeopleApplicationAgent)

- Dumb agent — just relays between user and wizard endpoint
- Wizard pattern: POST payload → wizard returns "missing: X" with question → agent asks user → adds answer → POST again → repeat until 200
- Wizard owns all brains: field ordering, validation, what's required
- Agent owns nothing about the application schema — self-updating when wizard changes
- 1 RESTTool pointing at wizard endpoint
- Instructions: "POST, relay the question, collect the answer, POST again until submitted"
- Two wizards already built and working E2E:
  - QuickApplyWizard — `POST /{tenant}/JobBoard/{jobBoardId}/QuickApplyWizard` (POC complete, demo ready)
  - ResumeApplyWizard — `POST /{tenant}/JobBoard/{jobBoardId}/ResumeApplyWizard` (POC complete, working E2E)
- See plans: `quick-apply-wizard.md`, `apply-with-resume.md`

## Decisions

- MAS out of scope — nobody using it in prod
- Intent classification out of scope — too heavy for 2 agents
- RouteToAgent round-trip works via client orchestration — AIVA pauses, client runs Enigma, feeds result back
- Only AIVA needs RouteToAgent — Enigma just finishes and the client handles the return
- Evals included in every story, never separate
- Routing instruction is trivial: "when user wants to apply, call RouteToAgent with Enigma"

## Open Questions

- Does our client already support the WAITING_FOR_TOOL_RESULT → run Enigma → tool-result callback flow?
- If not, client-side orchestration is a dependency (not our story — client/gateway team)
- POC needed but no time allocated

## Stories

1. Agent-to-agent routing — add RouteToAgent client tool to AIVA's config + instructions for when to route + evals
   - Agent-side only: tool definition + routing instructions in JSON
   - Dependency: client must support ClientTool round-trip (202 → tool-result)
