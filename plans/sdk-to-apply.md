# SDK-to-Apply: Bryte Chat on OpportunityDetail Page

## Goal
Add Bryte SDK chat to `/mordor/JobBoard/{jobBoardId}/OpportunityDetail?opportunityId={id}` so candidates can apply to jobs via chat.

## What We Know Works (from TalentPool, verified 2026-03-10)
- No mocks needed — real Bryte backend accepts OppAuthN token
- BryteProxyService forwards headers as-is
- Three key settings: `userContextPath`, `searchDispatchUrl` (local proxy), `displayChat: true`
- BryteAssistComponent.tsx is generic — reusable across pages
- OppAuthN token is service-level (tenant alias, not user) — works for anonymous

## How Bryte SDK Auth Works (from Confluence docs)
1. SDK sends requests through our proxy to Bryte backend
2. Proxy forwards: Cookie, Authorization, x-app-context, Accept, globaltenantid
3. Bryte backend uses `x-app-context` (Base64) to find `userContextPath`
4. Bryte backend calls BACK to our `{host}/{userContextPath}` to get AppUserContext
5. If AppUserContext is null/invalid → 422
6. AppUserContext must return: userLocale, userName, firstName, lastName, eeid
7. TalentPool's POC works by hardcoding tenantId (`1714709d-10c0-4bf0-a2ab-6538dce8a922`) and personId (`334F4E7D-010F-A502-F8FB-571BBE99FEE2`)

## Lessons Learned (2026-03-10)
- 422 comes from Bryte backend, NOT ASP.NET antiforgery
- `[AllowAnonymous]` on session-user-context + returning OK with empty data = Bryte rejects it
- `[IgnoreAntiforgeryToken]` on proxy, NOT `[AllowAnonymous]`
- Mount via wrapper component (OpportunityDetailBryteWidget), not standalone ReactDOM.render
- Confluence docs: pages 895445077 (UI SDK) and 1063034699 (Backend SDK)

## Target Page
- Controller: `OpportunityDetailController.cs` — `[AllowAnonymous][JobBoardSpecific]`
- View: `Index_Ignite.cshtml` (modern) — no SDK/Bryte references exist
- Route: `{tenantalias}/JobBoard/{jobBoardId}/{controller}/{action}/{id?}`
- Candidate-facing — anonymous + authenticated users

## What Needs Done

### 1. Fix session-user-context endpoint — BLOCKING
**File:** `Controllers/OpportunityDetailController.cs` (GetSessionUserContext method, ~line 418)
- Currently broken: `[AllowAnonymous]` + returns OK with empty data when unauth → Bryte 422
- **Fix:** Copy TalentPool's POC hack — hardcode tenantId + personId like `TalentPoolV2Controller.cs:77-120`
- Hardcode: tenantId `1714709d-10c0-4bf0-a2ab-6538dce8a922`, personId `334F4E7D-010F-A502-F8FB-571BBE99FEE2`
- Remove `[AllowAnonymous]`, use same auth pattern as TalentPool
- Reference: `Controllers/ExternalApi/v2/TalentPool/TalentPoolV2Controller.cs`

### 2. Controller: Add Bryte dependencies + proxy + ViewBag
**File:** `Controllers/OpportunityDetailController.cs`
- Inject: `IBryteProxyService`, `IIdentityServiceClient`, `IProductInstanceConfig`, `ITrsDomainService`
- Add `OpportunityDetailProxy(string path = null)` action — copy TalentPoolProxy, `[AllowAnonymous]`
- In Index(): set ViewBag props (GlobalTenantId, Token, BryteSearchDispatchUrlLocal, BryteSdkPreviewUrl, BryteStaticAssetUrl, DataCenter, EnvironmentType, ProductCode, UserId, LocaleCode)

### 3. Route: Add proxy catch-all BEFORE JobBoardSpecific
**File:** `Startup.cs`
```
endpoints.MapControllerRoute("OpportunityDetailProxy",
    "{tenantalias}/JobBoard/{jobBoardId}/OpportunityDetail/OpportunityDetailProxy/{*path}",
    new { controller = "OpportunityDetail", action = "OpportunityDetailProxy" });
```
Must go BEFORE the generic `JobBoardSpecific` route.

### 4. View: Add SDK init + script
**File:** `Views/OpportunityDetail/Index_Ignite.cshtml`
- Build appContext with `userContextPath = "api/opportunity/v2/session-user-context"`
- bryteConfig, bryteInitConfig — copy TalentPool pattern
- `displayChat: true`
- `store: { opportunityId, jobBoardId }`
- Load SDK script async
- Mount BryteAssistComponent

### 5. Widget: Minimal React wrapper
**File:** `Scripts/site/react-es6-components/Containers/JobBoard/OpportunityDetail/OpportunityDetailBryteWidget.tsx`
- Mounts BryteAssistComponent with config + initConfig props
- Reuse existing `BryteAssistComponent.tsx` from `0_Shared/`

## Key Files
| File | Role |
|------|------|
| `Controllers/OpportunityDetailController.cs` | Main target — proxy + ViewBag |
| `Controllers/ExternalApi/v2/TalentPool/TalentPoolV2Controller.cs` | Pattern for session-user-context |
| `Views/OpportunityDetail/Index_Ignite.cshtml` | View target — SDK init |
| `Startup.cs` | Route for proxy |
| `Controllers/BryteTalentPoolController.cs` | Pattern for proxy + ViewBag |
| `Views/BryteTalentPool/TalentPool.cshtml` | Pattern for SDK config |
| `Scripts/.../0_Shared/BryteAssistComponent.tsx` | Reuse as-is |

## Test
1. Navigate to `https://localhost:5001/mordor/JobBoard/b316e881-cab2-999a-b0a0-838bfaaff491/OpportunityDetail?opportunityId=dbfc772a-5659-5379-797f-ff2dc34f8be2`
2. FAB visible → click → chat opens → type "I want to apply" → get response
