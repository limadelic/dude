# Bryte SDK POC

## Win Condition (POC Done When This Passes)

Use magellan with a haiku sub-agent for ALL browser actions. Never claim done without this passing.

1. Navigate to `https://localhost:5001/mordor/JobBoard/b316e881-cab2-999a-b0a0-838bfaaff491/` (no login needed)
2. The **Bryte SDK FAB button** appears on the page
3. Click it — the **Bryte SDK chat panel** opens (not AIVAChatBotComponent — the SDK shell)
4. Type a message in it

✅ **That's it. We win.** AIVA responding is irrelevant for the POC — the SDK UI is the goal.

If FAB doesn't show → NOT done. The blocker is always `init()` health check on `searchDispatchUrl/health`.

## Reference: Only Agent Using Bryte SDK Today
- **Agent:** `ProPeopleAITalentPoolAgent`
- **Widget:** `Containers/Recruiters/BryteTalentPool/TalentPoolWidget.tsx` — mounts `BryteAssistComponent`
- **Feature:** `Containers/Recruiters/BryteTalentPool/TalentPoolWithBryte.tsx` — custom chat UI (UkgAiDrawer), session + messaging
- **View:** `Views/BryteTalentPool/TalentPool.cshtml` — loads SDK script, builds config server-side
- **Controller:** `Controllers/BryteTalentPoolController.cs` — resolves URLs from TRS, builds ViewBag

## Goal
Make AIVA (`ProPeopleCandidateAssistAgent`) work through Bryte SDK on the job board.

## How TalentPool Actually Uses the SDK

Two separate things happening:

### 1. Custom Chat UI (NOT the SDK)
`TalentPoolWithBryte.tsx` is a full custom chat built with Ignite components (`UkgAiDrawer`, `UkgAiSearchInput`, `UkgAiMessageBubble`). It handles:
- Session creation: `POST /{tenant}/BryteAssist/CreateBryteSession { agentName: "ProPeopleAITalentPoolAgent" }`
- Messaging: `POST /{tenant}/BryteAssist/SendMessageToBryte { Message, SessionId, BryteAgentName: "TalentPoolAgent", AdditionalContext }`
- Response parsing: `getJsonFromText()` for structured data (pools, candidates, skills, filters)
- Custom rendering: pool tables, candidate tables, skill chips, bullet lists, confirm/reject buttons

This is the conversational experience. It does NOT use the SDK for any of this.

### 2. SDK Shell (BryteAssistComponent)
`TalentPoolWidget.tsx` renders `BryteAssistComponent` as a sibling at the bottom:
```tsx
{props.isBryteAssistEnabled && props.bryteConfig && (
    <BryteAssistComponent config={props.bryteConfig} initConfig={props.bryteInitConfig} />
)}
```

The SDK shell gets:
- `config`: headers (x-app-context base64 + auth token), user (id, fullName, email, locale), searchDispatchUrl, staticAssetUrl, ldFields
- `initConfig`: `{ applicationId: 'recruiting-app', displayChat: false, credentials: 'include', store: { talentPoolIntent: null, bryteView: null } }`

`displayChat: false` — the SDK shell starts closed/hidden. It's not the primary chat UI.

### Config built server-side (TalentPool.cshtml)
```js
bryteConfig = {
    headers: {
        "x-app-context": "<base64 encoded appContext>",
        "Authorization": "<Bearer token>"
    },
    user: { id, fullName, email, locale },
    searchDispatchUrl: '/{tenant}/BryteTalentPool/TalentPoolProxy',
    staticAssetUrl: '<from TRS h-pexp-sxsuicdn>',
    ldFields: { userId, environment, dataCenter },
    locale, localeDateFormat: 'PP', localeTimeFormat: 'p'
};

bryteInitConfig = {
    applicationId: 'recruiting-app',
    displayChat: false,
    credentials: 'include',
    store: { talentPoolIntent: null, bryteView: null }
};
```

appContext (base64):
```json
{
    "trsServiceCode": "h-recr-api",
    "deploymentIdentifier": "recruiting-rec-web-rec-web-dev",
    "dataCenter": "<from ViewBag>",
    "environmentType": "<from ViewBag>",
    "productCode": "<from ViewBag>",
    "userContextPath": "MORDOR/BryteTalentPool/GetSessionDetails",
    "dateFormat": "MM/dd/yyyy",
    "tenantId": "<GlobalTenantId>",
    "userId": "<UserId>",
    "gmtOffset": "-5"
}
```

### URL resolution (BryteTalentPoolController)
- SDK script: TRS `h-pexp-sxssdkcdn` → fallback `https://suitex-bryte-sdk-dev.cdn.ultiproservices.com/preview/latest/bryte-sdk-shell-element.js`
- Static assets: TRS `h-pexp-sxsuicdn` → fallback `https://suitex-search-dev.cdn.ultiproservices.com/dev/latest`
- API gateway: TRS `h-pexp-sxsgtwext` → fallback `https://sxs029999d01m.pro.ukg.dev`
- Dispatch URL: `/{tenant}/BryteTalentPool/TalentPoolProxy` (proxy to gateway)

### Backend services
- `BryteAssistController.cs` — `CreateBryteSession(agentName)` + `SendMessageToBryte(dto)`
- `BryteAssistService.cs` — `CreateSession(agentName)` → DS API `/agents/by_name/{agentName}/sessions`, `MessageToBryte()` → `/sessions/{id}/messages`
- `BryteAssistClient.cs` — HTTP client, context routing switch on `BryteAgentName`
- `BryteTalentPoolController.cs` — `TalentPoolProxy` (requires auth + recruiter role), proxies to SuiteX gateway

## Key Files
- `Views/BryteTalentPool/TalentPool.cshtml` — SDK script + config
- `Containers/Recruiters/BryteTalentPool/TalentPoolWidget.tsx` — mounts BryteAssistComponent
- `Containers/Recruiters/BryteTalentPool/TalentPoolWithBryte.tsx` — custom chat UI
- `Scripts/site/react-containers/0_Shared/BryteAssistComponent.tsx` — SDK wrapper
- `Scripts/site/react-containers/0_Shared/BryteAssistHelpers.tsx` — BryteConfigService
- `Controllers/RecruitmentAdministratorSettings/BryteAssistController.cs` — session + message endpoints
- `Controllers/BryteTalentPoolController.cs` — URL resolution + proxy
- `Services/IntegrationModule/BryteAssistService.cs` — DS API client
- `Services/IntegrationModule/BryteAssistClient.cs` — HTTP + context routing

## CRITICAL DISTINCTION
- TalentPool agent = `ProPeopleAITalentPoolAgent` — recruiter tool, NOT AIVA
- AIVA = `ProPeopleCandidateAssistAgent` — candidate assistant, target of this POC
- TalentPool is only a **reference** for how to wire up the SDK shell — AIVA does not live there

## ⚠️ TalentPool Red Flag: SDK Is Hidden, Never Shown To Users

Code review confirmed SDK wiring is real (script loads, `init()` is called, web component renders) BUT:

`displayChat: false` = FAB hidden = **no user ever sees the SDK chat in TalentPool**

TalentPool built a full custom chat (`TalentPoolWithBryte.tsx`) and hid the SDK alongside it. The SDK shell is initialized but invisible. This means **nobody on the TalentPool team actually shipped the SDK as a visible chat experience**. They may have started the migration and stopped, or the SDK wasn't ready for their use case.

TalentPool is a reference for **how to wire up the SDK technically** — not for using it as the actual UI.

**Our goal is more ambitious**: we want the SDK to BE the visible chat (FAB shows, user clicks, SDK panel opens). `displayChat: 'close'` not `false`.

### What TalentPool gives us (valid reference):
- ✅ How to load the SDK script
- ✅ `customElements.whenDefined()` + 500ms delay + `init()` pattern
- ✅ How to build `appContext` + base64 encode it
- ✅ `BryteSearchDispatchUrl` = full URL: `${productInstanceConfig.BaseUrl}/{tenantAlias}/BryteTalentPool/TalentPoolProxy`
- ✅ TRS fallback URLs for SDK script and static assets
- ✅ `window.SuiteXSearch.navigateLink` navigation handler

### What TalentPool does NOT prove:
- ❌ That the SDK chat actually works end-to-end for users
- ❌ That the FAB renders correctly
- ❌ That conversations flow through the gateway correctly

## What the SDK Shell Actually Provides

The SDK shell is a **turnkey chat solution** — NOT just a container:
- Full chat UI: input box, message bubbles, streaming responses via SSE
- Conversation history + IndexedDB persistence
- 17+ result item renderers (cards, tables, navigation, markdown, charts, etc.)
- Welcome screen with suggested topics
- FAB button for open/close
- Voice input support
- Chain of Thought expandable section
- Feedback UI (thumbs up/down)

When you `dispatch()`, the SDK opens, routes to the agent, streams the response, and renders it. No custom chat UI needed.

## What AIVA Actually Is On The Job Board

AIVA on the job board is NOT the Bryte SDK shell. It is a **custom chat component** (`AIVAChatBotComponent`) that already existed, just gated behind a toggle.

### Key Files (AIVA custom chat)
- `Scripts/site/react-es6-components/Containers/JobBoard/AIVAChatBot.tsx` — the chat component
- `Controllers/JobBoardViewController.cs` — `ProxyAivaChat` action + ViewBag setup
- `Views/JobBoardView/Index.cshtml` and `Index_Ignite.cshtml` — renders `AIVAChatBotComponent`

### How it works
1. Controller sets ViewBag: `CandidateId`, `JobBoardId`, `TenantAlias`, `HostUrl`, `IdentityHostUrl`, `Token`, `SessionId`
   - `Token` = Bearer token from `identityServiceClient.GetOppAuthNAccessToken`
   - `SessionId` = from `jobAgentService.GetOrCreateSessionId(personId, token)` → hits DS API `/agents/api/v1/agents/by_name/ProPeopleCandidateAssistAgent/sessions`
2. Component renders chat UI with those props
3. Messages POST to `/{tenant}/JobBoard/{jobBoardId}/JobBoardView/ProxyAivaChat`
4. `ProxyAivaChat` forwards to `DataScienceUrl + /agents/api/v1/sessions/{sessionId}/messages`

### Current State (main branch, toggle removed)
- ✅ `EnableAIVAChat` toggle removed from `Index.cshtml` and `Index_Ignite.cshtml`
- ✅ `EnableAIVAChat` toggle removed from `JobBoardViewController` — ViewBag always populated
- ✅ AIVA chat UI shows on job board, opens, accepts messages
- ❌ DS API returning error on message send — `DataScienceUrl` may not be configured or `ProPeopleCandidateAssistAgent` not available in local env

### Next: Fix DS API connection
- Check `DataScienceUrl` in local recruiting.config
- Verify `ProPeopleCandidateAssistAgent` exists in that DS environment
- May need to point to a dev/staging DS endpoint

## ACTUAL GOAL: First Ever Visible SDK Shell

Nobody has shipped the Bryte SDK as a visible chat experience yet:
- Job board: `AIVAChatBotComponent` = custom hand-rolled chat. Feb 13 commit (ef4190055ce) changed 3 strings: "AIVA Chat" → "Bryte", "Close AIVA Chat" → "Close Bryte", "Chat with AIVA" → "Chat with Bryte". Zero SDK involvement.
- TalentPool: added `BryteAssistComponent` Feb 21 alongside their custom chat but hidden (`displayChat: false`). Transitioning, not done.

**Our POC = put `BryteAssistComponent` on the job board with `displayChat: 'close'` so the FAB is visible. First time the SDK shell is actually shown to a user.**

## Exact Implementation (copy TalentPool, adapt for job board)

### 1. JobBoardViewController.cs — add IBryteProxyService + ViewBag setup
- Add `IBryteProxyService` field + constructor param (not currently injected — must add)
- Copy the TalentPool controller ViewBag block, with these changes:
  - No feature toggle check (POC)
  - `BryteSearchDispatchUrl` = `$"{productInstanceConfig.BaseUrl}/{tenantAlias}/JobBoard/AivaSdkProxy"`
  - `userContextPath` in appContext = `"{tenantAlias}/JobBoard/GetSessionDetails"`
  - `UsUser.GetPersonId()` is null for anonymous → pass null, SDK fields are optional
  - Skip TRS lookups — hardcode `BryteSdkPreviewUrl` and `BryteStaticAssetUrl` fallback values directly

### 2. JobBoardViewController.cs — add AivaSdkProxy action
Copy `TalentPoolProxy` verbatim, with these changes:
- `[AllowAnonymous]` (job board is external, no auth check)
- No feature toggle check
- Hardcode `bryteApiBaseUrl = "https://sxs029999d01m.pro.ukg.dev"` (no TRS, no `SuiteXSearchUrl` field)
- Uses `IBryteProxyService.ProxyRequestAsync` same way

### 3. Index.cshtml / Index_Ignite.cshtml — build config and mount component
Copy TalentPool.cshtml block verbatim, with these changes:
- `userContextPath` = `"{tenantAlias}/JobBoard/GetSessionDetails"`
- `displayChat: 'close'` (not `false`) — we WANT the FAB visible
- `store: { aivaIntent: null }` instead of talentPool store
- Remove `AIVAChatBotComponent`, mount `BryteAssistComponent` instead
- Load SDK script: `<script async type="module" src="@ViewBag.BryteSdkPreviewUrl"></script>`

### 4. Verify
Use magellan + haiku agent: navigate to job board, FAB appears, click it, type a message. Done.

## Anonymous Candidates — Not An Auth Problem

"Anonymous" means the candidate hasn't logged into Candidate Presence. The backend can still produce everything the SDK needs:

- **Token**: `identityServiceClient.GetOppAuthNAccessToken(scopes, tenantAlias)` — only needs the tenant alias from the URL. No logged-in user required. Service-level token.
- **tenantId / GlobalTenantId**: repository lookup by tenant alias. No user required.
- **user.id**: no real personId for anonymous. Generate a session GUID. LaunchDarkly just needs something.

This is about what values to pass, not about blocking auth. The job board already has the tenant alias in the URL — everything else can be generated server-side.

Relevant Confluence pages:
- Feature - AIVA: https://engconf.int.kronos.com/pages/viewpage.action?pageId=921713284
- SDK docs: https://engconf.int.kronos.com/pages/viewpage.action?pageId=895445077
- ICP integration: https://engconf.int.kronos.com/pages/viewpage.action?pageId=1031701710

## SDK Init Facts (from Confluence docs)

- `init()` returns `false` if the health check on `searchDispatchUrl/health` fails → FAB never renders
- `searchDispatchUrl` MUST be same-origin or CORS-enabled — SDK hits it from the browser
- `displayChat` values: `'close' | 'open' | 'openFullScreen'` (boolean `false` also works as falsy = close)
- FAB only appears after `init()` returns `true`

## Branch Strategy
Start fresh from current main (toggle already removed). Do NOT pop the stash — two days of lying code, abandon it.
New branch off main: `poc/aiva-sdk` (or similar).

## Everything Resolved From TalentPool Code

### Health check — how it works
`TalentPoolProxy(string path = null)` — SDK hits `{searchDispatchUrl}/health`, `path="health"`, proxy forwards to `{gateway}/health`, returns 200, FAB appears. `AivaSdkProxy` copies this exactly.

### Gateway / agent routing — UNKNOWN, TWO POSSIBILITIES

TalentPool's SDK is `displayChat: false` (hidden). All their real messaging goes through the custom chat, not the SDK shell. The `store: { talentPoolIntent: null, bryteView: null }` values are null. Nobody has shipped the SDK as a working visible chat. We cannot confirm or deny that TalentPool's SDK routing actually works.

**Possibility A (optimistic):** The gateway is already configured for `h-recr-api` + `recruiting-rec-web-rec-web-dev` and knows how to route to the right agent. Copying TalentPool's appContext structure and pointing `userContextPath` at a job board endpoint works out of the box. AIVA responds.

**Possibility B (pessimistic):** The gateway isn't configured for AIVA at all, or the `store` keys / `userContextPath` response need specific values that nobody has documented. TalentPool's SDK wiring is scaffolding that was never validated. AIVA doesn't respond through the SDK.

We won't know which until we run it. The plan proceeds — if A, great. If B, that's the next problem to solve.

### GetSessionDetails — needed for agent routing
Gateway calls `userContextPath` to get user/session context for routing. TalentPool's `GetSessionDetails` returns `isAuthenticated`, `personId`, `tenantId`, `tenantAlias`, `roles`. We add the same endpoint to `JobBoardViewController`. For anonymous: return `isAuthenticated: false`, `personId: null`, `tenantAlias` from URL.

### IBryteProxyService — MUST ADD to JobBoardViewController
`JobBoardViewController` has no `IBryteProxyService` injection (confirmed by grep). Must add field + constructor param.

### ITrsDomainService — skip for POC
TalentPool resolves gateway URL from TRS via class-level `SuiteXSearchUrl` field. For POC, hardcode `"https://sxs029999d01m.pro.ukg.dev"` directly in `AivaSdkProxy`. No new dependency needed.
