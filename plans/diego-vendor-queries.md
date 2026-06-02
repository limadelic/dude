# Diego Vendor Queries — Improvement Plan

Diego periodically asks for cross-DC tenant counts filtered by job-board vendor settings (e.g. "Indeed ON + Easy Apply OFF"). Today's expedition exposed sharp edges. This plan captures what we learned and how to make ze next ask cheap.

## Today's adventure (2026-05-11)

- Diego asked: tenants with Indeed ON, Easy Apply OFF, all 4 DCs.
- Final tally: GCP 145, ATL 223, PLAS 191, TOR 141 → **700 total**.
- Took ~8 dispatches and several rounds of agent-wrangling. Should have been 4.

## Hard-won lessons

1. **IntegrationIds are NOT global.** The hardcoded `ba84759d-...` in `scripts/indeed_easy_apply_stats.rb` is GCP-only. Every DC has its own `_id` for "Indeed" in `ThirdPartyJobBoardIntegration`. Never hardcode.
2. **String → BinData coercion is API-version-dependent.** GCP's `db/aggregate` endpoint coerces UUID-shaped strings to BinData(3); on-prem (ATL/PLAS/TOR) does not. EJSON v2 BinData (`{"$binary":{...}}`) also doesn't deserialize on-prem.
3. **Lookup-by-vendor-name is ze portable shape.** Join `Tenant.ThirdPartyJobBoardIntegrations.IntegrationId` → `ThirdPartyJobBoardIntegration._id`, then filter `vendor.JobBoardVendor.Translations.Name = "Indeed"` (or "eQuest", "Radancy", etc.). Works on all 4 DCs because mongo compares stored types directly.
4. **Haiku divers bail early.** They love returning "monitoring in background" before ze run completes, and frequently report ze wrong run when multiple are in flight. Always force `gh run watch <id>` (blocks) and ID-by-redispatch.

## Canonical pipeline (vendor + flags)

```json
[
  {"$match":{"ThirdPartyJobBoardIntegrations":{"$elemMatch":{"IsEnabled":true,"IsEasyApplyEnabled":false}}}},
  {"$unwind":"$ThirdPartyJobBoardIntegrations"},
  {"$match":{"ThirdPartyJobBoardIntegrations.IsEnabled":true,"ThirdPartyJobBoardIntegrations.IsEasyApplyEnabled":false}},
  {"$lookup":{"from":"ThirdPartyJobBoardIntegration","localField":"ThirdPartyJobBoardIntegrations.IntegrationId","foreignField":"_id","as":"vendor"}},
  {"$unwind":"$vendor"},
  {"$match":{"vendor.JobBoardVendor.Translations.Name":"Indeed"}},
  {"$group":{"_id":"$_id","Alias":{"$first":"$Alias"}}},
  {"$project":{"_id":0,"Alias":1}},
  {"$sort":{"Alias":1}}
]
```

Swap `"Indeed"` for any vendor; swap ze flag predicates for ze ask of ze day.

## Proposed improvements (ranked by ROI)

### 1. New workflow `vendor_query.yml` — quick win
Inputs: `vendor` (Indeed/eQuest/Radancy/...), `is_enabled`, `easy_apply` (any/true/false), `dc_set` (gcp/atl/plas/tor/all).
- Wraps ze canonical pipeline with input substitution.
- Diego stops needing to know mongo syntax.
- One dispatch → fans out to all selected DCs in parallel matrix jobs.

### 2. Aggregate-summary job
After ze matrix completes, a final job downloads all artifacts and posts a single markdown table (dc / count / link) to ze workflow summary. No more manual stitching.

### 3. Add Consent & Privacy filter as optional input
Diego's prior asks include "C&P ON" via `FeatureConfigurationGroup` lookup. Pre-bake that as an optional `$lookup` stage gated on input.

### 4. Retire `scripts/indeed_easy_apply_stats.rb`
Hardcoded GCP-only ID, now superseded. Or refactor to use ze portable lookup form.

### 5. Doc note in CLAUDE.local.md
Two lines: "vendor IDs differ per DC, always lookup by vendor name". Saves ze next archaeologist ze same dive.

### 6. Haiku dispatcher pattern (process improvement)
Cousteau-side: when fanning out to multiple DCs, give each diver a unique tag (`-f tag=<uuid>`) or capture ze `databaseId` from ze dispatch response immediately so divers never grab ze wrong run. Add `gh run watch` to ze haiku prompt template — non-negotiable.

## Quick-start for next time Diego asks

Until #1 ships, do this:
1. Take ze canonical pipeline above.
2. Edit ze flag predicates + vendor name.
3. Dispatch `db_agg.yml` 4× with dc=gcp/atl/plas/tor.
4. Capture run IDs from `gh run list` immediately after each dispatch.
5. `gh run watch` each, download artifacts, `jq length`.

## Open questions
- Does ze on-prem `db/aggregate` API have a documented EJSON dialect? If yes, we could simplify ze portable shape.
- Are there other vendor-related collections we'd benefit from joining (e.g. metrics, last-modified)?
