# REC Enigma — Demo Checklist

## ⚠️ THIS FILE IS SHARED — WATCH IT

Another agent (smith session) writes answers and updates here. You MUST watch for changes:

```bash
# Get current hash, then watch for changes
HASH=$(md5 -q ~/.claude/plans/rec-enigma.md)
~/.claude/skills/await/wait-until.sh "test \$(md5 -q ~/.claude/plans/rec-enigma.md) != '$HASH'"
```

Run this in background (`run_in_background: true`). When it fires, re-read the file — new answers or instructions were added. Then re-watch with the new hash.

**When you have questions**, write them in this file under a "Questions" section. The other agent is watching too and will answer.

## Goal

Show the full loop: user chats → agent asks wizard questions one by one → collects answers → redirects to QuickApply with fields pre-filled.

## Architecture (read this first)

```
User (localhost REC app)
  → Chat widget (ukg-bryte-assist-shell SDK element)
    → SDK dispatch() creates agent session via BFF
      → BFF POSTs /agents/api/v1/agents/by_name/ProPeopleApplicationAgent/sessions
      → Agent receives message, calls QuickApplyWizard tool
        → QuickApplyWizard POSTs to rec-preview (STUBBED via Guillotine)
        → Guillotine returns next field: {field, question, type}
      → Agent presents question to user
      → User answers → agent POSTs again with answer → next field
      → When wizard returns {status: 'complete', fields: {...}}
      → Agent calls RedirectToQuickApply (ClientTool)
    → SDK posts clientTool event via postMessage
  → Host app catches postMessage, builds URL, redirects
  → QuickApply page reads query params, pre-fills form
```

## What's done

- [x] QuickApplyTab.tsx — hydrate form from query params (`firstName`, `lastName`, `email`, `phoneNumber`, `candidateConsent`)
- [x] OpportunityDetailBryteWidget.tsx — dispatch config for ProPeopleApplicationAgent
- [x] BryteAssistComponent.tsx — accepts `dispatchConfig` prop, calls `element.dispatch()` after init
- [x] BryteAssistComponent.tsx — register `RedirectToQuickApply` via postMessage listener
- [x] QuickApply redirect URL includes JobBoard path segment
- [x] QuickApplyController.cs — bypassed ToggleableFeature.QuickApply and OpportunityType checks for POC
- [x] Verified: postMessage → redirect → form pre-filled (John, Doe, john@test.com, 1112223333)

## MISSING: Agent Context (must do)

The agent's QuickApplyWizard tool interpolates its POST URL from context. Without this, the wizard has no endpoint and the loop won't work.

**~~SDK store~~ won't work.** `store` is SDK-local only — never forwarded to the BFF or agent.

**Context comes through the Intent Registry entry's `customContext` field.** When we register the intent in BryteHub (step 4 of the pipeline), we configure:

```json
{
  "customContext": [
    { "key": "rec.base_uri", "type": "hardcoded", "value": "https://rec-preview.dlas1.ucloud.int" },
    { "key": "rec.path", "type": "hardcoded", "value": "MORDOR/api/applications" },
    { "key": "rec.opportunity_id", "type": "hardcoded", "value": "20badf49-0d7e-c88c-a5b6-070e96f79308" }
  ]
}
```

The BFF's `AgentsContextCreatorService.getCustomContext()` reads these from the intent config and includes them in the agent message context.

**This is blocked on the intent training pipeline** — same as the BFF routing. Both unblock at step 4.

## What's NOT done — connecting to the actual agent

The redirect works in isolation (postMessage test). But **nobody has connected the chat widget to ProPeopleApplicationAgent yet**. The chat needs to:

1. Create an agent session
2. Send messages to it
3. Receive responses (including tool calls)

### How dispatch works (from SDK source)

The SDK element exposes `dispatch()` method (`element-main.ts:58-60`):

```typescript
await bryteElement.dispatch({
  id: 'apply-job',
  label: 'I want to apply for this job',
  actionResponder: 'ProPeopleApplicationAgent'
});
```

This sends the label as a message routed to the named agent. The BFF then:
1. Calls `CreateAgentSessionAction` → POSTs to `/agents/api/v1/agents/by_name/ProPeopleApplicationAgent/sessions`
2. Calls `SendAgentMessageAction` → POSTs to `/agents/api/v1/sessions/{sessionId}/messages`

**Required BFF headers** (from `AiServiceHeaders.kt`):
- `Authorization: Bearer {token}`
- `ds-tenant-id`, `ds-user-id`, `ds-product-id`, `ds-session-id`

**The BFF (search-dispatch-url) must be reachable from localhost.** Check what URL `BryteAssistComponent.tsx` sets as `search-dispatch-url` on the element.

### How ClientTool events reach the host

When the agent calls RedirectToQuickApply, the SDK sends a postMessage:
```javascript
// SDK → Host
window.postMessage({
  type: 'BryteAssistSDK',
  name: 'clientTool',
  payload: { name: 'RedirectToQuickApply', args: { firstName: '...', ... } }
}, '*')
```

The host catches it with `window.addEventListener('message', ...)`. This part is done.

## Guillotine — CRITICAL for the demo

The agent's QuickApplyWizard tool POSTs to rec-preview. There is no real wizard endpoint — **Guillotine stubs the responses**.

### Setup on rec-preview

Guillotine must be enabled on rec-preview AND stubs must be created before chatting.

**Guillotine API:**
```
Host: https://rec-preview.dlas1.ucloud.int
Endpoint: /internalapi/stub
Header: X-ApiKey: someSecretKeyGoesHere
```

**Create stubs (one per wizard step, in order):**

```bash
# Step 1: firstName
curl -X POST https://rec-preview.dlas1.ucloud.int/internalapi/stub \
  -H "X-ApiKey: someSecretKeyGoesHere" \
  -H "Content-Type: application/json" \
  -d '{"Method":"POST","Url":"applications","Status":200,"Response":{"field":"firstName","question":"What is your first name?","type":"text"},"Once":true}'

# Step 2: lastName
curl -X POST https://rec-preview.dlas1.ucloud.int/internalapi/stub \
  -H "X-ApiKey: someSecretKeyGoesHere" \
  -H "Content-Type: application/json" \
  -d '{"Method":"POST","Url":"applications","Status":200,"Response":{"field":"lastName","question":"What is your last name?","type":"text"},"Once":true}'

# Step 3: email
curl -X POST https://rec-preview.dlas1.ucloud.int/internalapi/stub \
  -H "X-ApiKey: someSecretKeyGoesHere" \
  -H "Content-Type: application/json" \
  -d '{"Method":"POST","Url":"applications","Status":200,"Response":{"field":"email","question":"What is your email address?","type":"text"},"Once":true}'

# Step 4: candidateConsent
curl -X POST https://rec-preview.dlas1.ucloud.int/internalapi/stub \
  -H "X-ApiKey: someSecretKeyGoesHere" \
  -H "Content-Type: application/json" \
  -d '{"Method":"POST","Url":"applications","Status":200,"Response":{"field":"candidateConsent","question":"Do you consent to us processing your data for this application?","type":"boolean"},"Once":true}'

# Step 5: complete
curl -X POST https://rec-preview.dlas1.ucloud.int/internalapi/stub \
  -H "X-ApiKey: someSecretKeyGoesHere" \
  -H "Content-Type: application/json" \
  -d '{"Method":"POST","Url":"applications","Status":200,"Response":{"status":"complete","fields":{"firstName":"John","lastName":"Doe","email":"john@test.com","candidateConsent":"true"}},"Once":true}'
```

**Clear all stubs:** `curl -X DELETE https://rec-preview.dlas1.ucloud.int/internalapi/stub -H "X-ApiKey: someSecretKeyGoesHere"`

**List stubs:** `curl https://rec-preview.dlas1.ucloud.int/internalapi/stub -H "X-ApiKey: someSecretKeyGoesHere"`

### Guillotine on localhost

REC app on localhost also needs Guillotine enabled. The `useGuillotine` feature toggle must be on. Check REC app config for how to enable it locally. Without it, `/internalapi/stub` won't exist on localhost.

**Note:** The agent's wizard tool POSTs to rec-preview (not localhost) because the context sets `base_uri: 'https://rec-preview.dlas1.ucloud.int'`. So guillotine stubs go on rec-preview. Localhost just needs the chat widget + redirect working.

## Context passed to agent session

When creating the agent session, this context tells the wizard tool where to POST:
```json
{
  "rec": {
    "base_uri": "https://rec-preview.dlas1.ucloud.int",
    "path": "MORDOR/api/applications",
    "opportunity_id": "20badf49-0d7e-c88c-a5b6-070e96f79308"
  }
}
```

This context must be passed when calling `dispatch()` or creating the session. Check how the SDK passes context — likely via `element.page()` or in the init config `store` property.

## Demo steps

1. REC app running on localhost
2. Set up guillotine stubs on rec-preview (curl commands above)
3. Open job board page with chat widget
4. Click/trigger dispatch to ProPeopleApplicationAgent
5. Agent calls wizard stub → asks "What is your first name?"
6. Answer each question → agent POSTs again → next question
7. After all answers → agent calls RedirectToQuickApply
8. Page redirects to `/JobBoard/{id}/QuickApply?firstName=John&lastName=Doe&email=john@test.com&candidateConsent=true`
9. QuickApply form is pre-filled

## Files changed

| File | What |
|------|------|
| `BryteAssistComponent.tsx` | dispatch to Enigma + postMessage listener for ClientTool |
| `OpportunityDetailBryteWidget.tsx` | dispatch config prop |
| `QuickApplyTab.tsx` | read query params, hydrate form |
| `QuickApplyController.cs` | bypassed feature toggle for POC |

## Remaining blocker

**Verified:** `dispatch()` fires successfully and SDK sends `POST /answer-specific-intent/{conversationId}?intent=ProPeopleApplicationAgent` to BFF. But the BFF returns HTTP 500 (`retrofit2.HttpException`, responder: `ConversationAsstSearch`). The BFF can't route to the agent.

**Root cause:** The BFF instance resolved via TRS (`sxs029999d01m.pro.ukg.dev`) does not have ProPeopleApplicationAgent registered or can't reach the DS agent gateway.

**Checked:**
1. ✅ `search-dispatch-url` = `https://localhost:5001/mordor/BryteProxy` → proxy forwards to BFF via TRS
2. ✅ Proxy now forwards query params (fixed `Request.QueryString`)
3. ❌ BFF returns 500 when `intent=ProPeopleApplicationAgent` — agent not registered in this BFF instance
4. ✅ Guillotine stubs set up on rec-preview (5 wizard steps)

**Answers (from bryte-bff source code):**

1. **Why 500**: The BFF calls `IntentRegistryService.getIntentDetails("ProPeopleApplicationAgent")` which GETs `/api/v1/intents/ProPeopleApplicationAgent` from the Intent Registry. The agent is NOT registered there yet → 404 → retrofit exception → 500. See `ActionsProcessor.kt:492-504`.

2. **PR #1192 is NOT enough**: PR #1192 is the NER metadata pipeline (for intent classification/training). The Intent Registry is a SEPARATE thing — it's a microservice with its own data. The agent must be registered in the Intent Registry via BryteHub `/registry-form`. This is step 4 of the intent training plan (`~/.claude/plans/enigma-intent-training.md`).

3. **No bypass possible**: The BFF has NO direct agent session endpoint. ALL agent routing goes through ChainActions → IntentRegistry lookup → CreateAgentSessionAction. There is no shortcut.

4. **What the Intent Registry entry needs** (from `IntentHandler.kt:208` and test fixtures):
```json
{
  "name": "ProPeopleApplicationAgent",
  "type": "AGENT",
  "steps": [
    {
      "step": 0,
      "responseCard": [
        { "actionType": "create-agent-session", "agentName": "ProPeopleApplicationAgent", "version": "latest" },
        { "actionType": "send-agent-message", "agentName": "ProPeopleApplicationAgent", "includeContext": true }
      ]
    }
  ]
}
```

5. **Sequence to unblock**: PR #1192 merge → NER training runs → register intent in BryteHub → enable feature flag → BFF can route to agent. This is the intent training plan.

6. **Workaround for NOW**: Mock the Intent Registry response on the BFF side. If the BFF resolves via TRS to `sxs029999d01m.pro.ukg.dev`, we could stub the registry response there. Or run a local BFF with a mocked registry. Ask Maykel which is faster.

## Questions + Answers

1. **How do we unblock the BFF?**
   - **Answer: (a) is the only real path.** Register in Intent Registry via BryteHub. This requires the full pipeline: PR #1192 merge → NER training → register intent → feature flag. PR #1192 is waiting on Checkmarx (last check), then we self-merge.
   - (b) won't work — the BFF calls the Intent Registry service via HTTP, not a local file we can stub.
   - (c) all BFF instances use the same Intent Registry service — no instance has the agent registered yet.
   - **We're blocked until the intent training pipeline completes.**

2. **Is the `store.rec` context being read?**
   - **Answer: NO.** `store` is SDK-local only (persisted in browser IndexedDB). It is NEVER sent to the BFF or agent. Confirmed from source:
     - `SharedStateService` stores it locally (`shared-state-manager.service.ts:85`)
     - `DataService` HTTP requests don't include store data (`data.service.ts:75-83`)
     - `AgentsContextCreatorService.createContext()` builds context from BFF backend services only — never from SDK store
   - **The rec context must come through the intent registry's `customContext` field** (hardcoded values, TRS lookups, or env vars). This gets configured when we register the intent in BryteHub (step 4 of the pipeline).
   - For the demo, we can hardcode the rec context values in the intent registry entry's `customContext` config.
