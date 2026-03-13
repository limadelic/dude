# Bryte SDK — What Actually Works

## TalentPool — DONE (poc/bryte-sdk branch, pushed)

### Changes from main (total: 7 insertions, 20 deletions)
1. Remove toggles: `TalentPoolWithBryte`, `NewNavigation`, `EnableBryteAssistForPools`, `GlobalTenantId.HasValue`
2. `userContextPath = "api/talentpool/v2/session-user-context"` (Naseeb said)
3. `searchDispatchUrl: '@ViewBag.BryteSearchDispatchUrlLocal'` (Naseeb said)
4. `displayChat: true` (was `false` — shows the chat panel)
5. `isBryteAssistEnabled = true` (was toggle-gated)

### How it works
- SDK script loads from CDN (`suitex-bryte-sdk-dev.cdn.ultiproservices.com`)
- SDK calls `searchDispatchUrl/health` → proxy forwards to real Bryte backend → 200
- SDK calls `searchDispatchUrl/api/v1/init-bryte` → proxy forwards → real backend validates token → 200
- User types message → SDK calls `searchDispatchUrl/api/v1/conversations` → proxy forwards → SSE stream back
- BryteProxyService forwards ALL headers as-is (Authorization, cookies, x-app-context, etc.)
- OppAuthN token from local dev works fine against real Bryte backend

### What NOT to do
- Do NOT mock init-bryte or health — real backend works
- Do NOT hardcode OAuth credentials — `IToken` service exists
- Do NOT change BryteProxyService — it works as-is
- The poc/aiva-sdk branch mocked everything and was wrong

## Architecture (how SDK connects)

```
Browser → SDK (CDN) → searchDispatchUrl (our proxy) → BryteProxyService → Real Bryte Backend
```

Proxy route in Startup.cs:
```
endpoints.MapControllerRoute("BryteTalentPoolProxy",
    "{tenantalias}/BryteTalentPool/TalentPoolProxy/{*path}",
    new { controller = "BryteTalentPool", action = "TalentPoolProxy" });
```

## SDK Config (built in TalentPool.cshtml)

```js
bryteConfig = {
    headers: { "x-app-context": "<base64>", "Authorization": "<Bearer token>" },
    user: { id, fullName, email, locale },
    searchDispatchUrl: '<proxy URL>',
    staticAssetUrl: '<CDN>',
    ldFields: { userId, environment, dataCenter }
};

bryteInitConfig = {
    applicationId: 'recruiting-app',
    displayChat: true,
    credentials: 'include',
    store: { talentPoolIntent: null, bryteView: null }
};
```

appContext (base64-encoded):
```json
{
    "trsServiceCode": "h-recr-api",
    "userContextPath": "api/talentpool/v2/session-user-context",
    "tenantId": "<GlobalTenantId>",
    "userId": "<PersonId>",
    "dataCenter": "<from config>",
    "environmentType": "<from config>"
}
```

## Naseeb Arora's PRs
- #5248 — Bryte assist on Talent pool
- #5306 — Adding proxy for Bryte SDK
- #5374 — Adding a component for Bryte Assist

## Auth Tokens
- `IToken.Rec` — recruiting token (OppAuthN or UkgAuthN based on toggle)
- `IToken.DS` — DataScience gateway token (UkgAuthNInternal, audience: `https://service-datascience-gateway.ukg.net`)
- BryteProxyService just forwards browser's Authorization header — no server-side token needed for proxy
