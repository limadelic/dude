# Bryte SDK POC

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

## Finding: TalentPool Isn't Really Using the SDK

TalentPool loads the SDK shell but doesn't use it for conversation. `TalentPoolWithBryte.tsx` rebuilds the entire chat with custom Ignite components (UkgAiDrawer, UkgAiSearchInput, UkgAiMessageBubble). The SDK shell sits alongside with `displayChat: false` doing nothing.

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

## POC Approach

Drop the SDK shell on the job board. Let it be the chat. No custom components.

1. Load SDK script in job board view
2. Configure: headers, user, searchDispatchUrl, staticAssetUrl, ldFields
3. `init()` — SDK renders FAB, user clicks to open
4. SDK talks to gateway → gateway routes to AIVA agent → SDK renders responses

## What I Still Need to Figure Out
- Does the SuiteX gateway know about `ProPeopleCandidateAssistAgent`? If not, we need to register it or proxy
- How does the gateway determine which agent to route to? Classification? Config?
- Anonymous candidate on job board — what user/headers does the SDK need at minimum?
- Do we need `dispatch()` with agent lock to target AIVA, or does classification handle it?
