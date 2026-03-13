# Multi-Agents

## Conclusion

**No multi-agent code needed.** BryteHub + SuiteX handles routing via intent classification.
Register agents, train intents with golden phrases, platform routes automatically.

## How It Works (Full Stack)

1. **bryte-assist-sdk** (TypeScript) — shell, loads the chat MFE
2. **suitex-search-web** (TypeScript) — chat UI, sends messages via SSE to backend
3. **suitex-search-conversation-assistant** (Kotlin) — chat backend, manages sessions, handles RouteToAgent
4. **DS API** (Python) — agent service, sessions, messages
5. **DS SDK** (Python) — agent runtime, graph execution

### RouteToAgent flow

1. User types in Bryte → intent classifier picks the right agent
2. Chat backend detects RouteToAgent → finds target agent
3. Creates session with target agent → sends query → returns response
4. All automatic — no code needed from us

## SDK Status

### TalentPool — WORKING (poc/bryte-sdk, verified 2026-03-10)
- SDK chat works end-to-end with `displayChat: true`
- Three changes from main + toggle removals
- See `~/.claude/plans/bryte-sdk.md` for details

### SDK Blockers for GA
- Consent flow — SDK assumes employees, no mechanism for external candidates
- File upload — no upload in Bryte Assist MFE (needed for resumes)

## What's Left

1. Register AIVA in BryteHub under SuiteX-Search
2. Train intent classifier with golden phrases
3. Solve consent flow for GA
4. Solve file upload for GA
