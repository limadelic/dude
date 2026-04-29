# Bryte SDK Auth — How It Works and How to Fix It

## Architecture

```
Browser → SDK (ukg-bryte-assist-shell)
  → BryteProxy (our controller, AllowAnonymous)
    → madhavweb.dev.us.corp/handlers/WayfindingHomeHubProxy.ashx/Experience.Search.Api
      → Real Bryte BFF (sxs029999d01m.pro.ukg.dev)
```

The SDK sends requests to `searchDispatchUrl` which points to our BryteProxy.
Our proxy forwards to madhavweb's WayfindingHomeHubProxy with hardcoded session cookies.
Madhavweb's handler adds proper server-side auth and forwards to the real BFF.

## Why Not Hit the BFF Directly?

Tried everything — all return 422 "Access denied for this Service" on init-bryte:
- `GetUkgAuthNInternalAccessToken("https://service-datascience-gateway.ukg.net")` — client-credentials token, issuer welcome-staging.ukg.dev
- `GetOppAuthNAccessToken` — NovaAuth JWT
- DS-* headers (DS-Product-ID, DS-Parent-Product-ID, DS-User-Id, DS-Tenant-ID, DS-Session-ID)
- 14 different header combinations tested
- Real login cookies from suitebugbash24 and gqssuiterec02

search-config works with no auth (200 directly). Only init-bryte is locked down.

The BFF requires requests to come through WayfindingHomeHubProxy which adds auth the BFF trusts.
This is how the official Bryte demo app works too (ukg-bryte-assist-shell repo).

## Madhavweb Credentials

- URL: https://madhavweb.dev.us.corp/default.aspx
- Username: usa-canu
- Password: password
- Tenant ID: 92da8395-6c92-4f08-8a6c-24ecf815abfa

## Refreshing Cookies (They Expire!)

When Bryte chat stops working (init-bryte returns 422 through our proxy):

1. **Login via arana** to madhavweb.dev.us.corp with the creds above
2. **Capture cookies** — run `() => document.cookie` in browser
3. **Extract 3 values**: `ASP.NET_SessionId`, `loginToken`, `UltiProNET`
4. **Update** `MadhavwebCookies` in `Product/Presentation.Web.UI.NetCore/Controllers/BryteProxyController.cs`
5. **Build + restart** the app
6. **Verify**: `curl -sk https://localhost:5001/mordor/BryteProxy/api/v1/init-bryte` → should return 200

## Other Environments Tested

| Environment | Bryte Works? | Notes |
|-------------|-------------|-------|
| madhavweb.dev.us.corp | YES | Used for POC proxy |
| suitebugbash24.ukg.dev | NO | 404 org not found in OAuth |
| gqssuiterec02.ukg.dev | NO | Shell not found, SDK fails to init |
| Direct BFF (sxs029999d01m) | NO | 422 Access denied on init-bryte |

## Key Repos

| Repo | What | Location |
|------|------|----------|
| ukg-bryte-assist-shell | Demo app + proxy | ~/dev/ext/ukg-bryte-assist-shell |
| ukg-bryte-assist-sdk | SDK source | ~/dev/ext/ukg-bryte-assist-sdk |
| ukg-bryte-mock-server | Mock BFF (port 8083) | ~/dev/ext/ukg-bryte-mock-server |
| onboarding | ONB's working integration | ~/dev/ext/onboarding |

## What ONB Does Differently

ONB hits the BFF directly using:
- `IClientCredentialsTokenService.GetToken(tenantAlias, IdentityVersion.OPPAuthN, scopes)`
- Headers: Authorization, X-App-Context, DS-User-Id, X-Tenant-Id
- Their tenant is registered with the BFF — ours isn't

## For Production

Get our tenant registered with the Bryte BFF team so we can hit it directly (like ONB).
Then replace madhavweb proxy URL with TRS-resolved BFF URL and use proper token auth.

## Files

| File | Purpose |
|------|---------|
| `Controllers/BryteProxyController.cs` | Proxy with hardcoded cookies |
| `Services/IntegrationModule/BryteProxyService.cs` | HTTP forwarding, SSE streaming |
| `Controllers/OpportunityDetailController.cs` | bryteConfig (token, URLs) |
| `Views/OpportunityDetail/Index_Ignite.cshtml` | SDK widget rendering |
| `Scripts/.../BryteAssistComponent.tsx` | React wrapper for SDK |
| `Scripts/.../OpportunityDetailBryteWidget.tsx` | Widget component |
