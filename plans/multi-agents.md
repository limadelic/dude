# Multi-Agents

## Conclusion

**No multi-agent story needed.** The SDK (BryteAssist) handles routing automatically.

Both AIVA and Enigma must be registered in **BryteHub under SuiteX-Search** (not NREC). The SDK + chat backend (suitex-search-conversation-assistant) handle RouteToAgent end-to-end. No client-side code to write.

## How It Works (Full Stack)

### The chain (user types → agent responds)

1. **bryte-assist-sdk** (TypeScript) — shell, loads the chat MFE → `ds/bryte-sdk`
2. **suitex-search-web** (TypeScript) — chat UI, sends messages via SSE to backend → `ds/bryte-web`
3. **suitex-search-conversation-assistant** (Kotlin) — chat backend, manages sessions, handles RouteToAgent → `ds/bryte-bff`
4. **DS API** (Python) — agent service, sessions, messages, tool-result → `ds/api`
5. **DS SDK** (Python) — agent runtime, graph execution, ClientTool interrupts → `ds/sdk`
6. **Agent configs** — AIVA, Enigma definitions → `ds/agents` + `aiva/` + `enigma/`

### RouteToAgent flow (already implemented in #3)

1. AIVA calls RouteToAgent → DS API returns 202 with `intent_name` + `detailed_summarized_query`
2. Chat backend (`SendAgentMessageAction.kt`) detects RouteToAgent → throws `RouteToAgentException`
3. `ConversationHandlerService` catches it → uses intent to find target agent
4. Creates new session with target agent → sends query → returns response
5. All automatic — no code needed from us

### Routing config (BryteHub)

- Routing is configured via examples/instructions in BryteHub
- "To route to which agent you need to train through the BryteHub... write few examples"
- Agent must be under SuiteX-Search for SDK to find it

## POC (this branch: aiva-enigma)

### What we proved

- RouteToAgent works at the DS API level — AIVA routes to Enigma, Enigma responds, response comes back
- E2E test: `test_routes_to_enigma_on_apply` — talk to AIVA, say "I want to apply", get Enigma's response
- `session.rb` simulates what the chat backend does in prod (RouteToAgent round-trip)

### Agent configs

- **AivaEnigma** — AIVA copy with RouteToAgent ClientTool + routing instruction (`aiva/config/aiva.json`)
- **Enigma** — simple hello agent, placeholder for wizard (`enigma/config/enigma.json`)

### Test infra added

- `lib/ds/agent.rb` — `Agent.tool_result` method (posts to `/actions/tool-result`)
- `lib/ds/session.rb` — `Session.tool_result` + auto RouteToAgent handling in `Session.msg`

## SDK Adoption (from meeting 2026-03-09)

- SDK is a must — not optional, for beta too
- Agents must be in SuiteX-Search (not NREC) for SDK to find them
- SDK handles sessions automatically — no session creation needed
- UX must follow SDK — no custom UI stories
- **Known blockers:**
  - Consent flow may not work with SDK
  - No file upload in SDK (affects ResumeApplyWizard)

## What's Left

1. Register both agents in BryteHub under SuiteX-Search
2. SDK adoption — move off custom website to SDK
3. Enigma wizard integration — replace hello with actual wizard relay
4. Solve consent for SDK
5. Solve resume upload for SDK
