# PA POC — Position Automation Open-Position Detection

## Status: SHIPPED to branch (POC scope, dormant)

Branch `poc/pa` pushed to origin. Commit `ce02b31e502` — "PA POC: open-position event subscription scaffold". No PR opened yet.
PR creation link: https://github.com/UKGEPIC/recruiting-app/pull/new/poc/pa

## What this POC is for

A demo for a customer conversation. Customers did NOT want opportunities created automatically. So this POC ships **dormant behind a toggle** — proves we have the wiring in place to detect "position became Open" and call out to an external agent, without actually doing it in any prod tenant.

The agent itself is a parallel POC owned elsewhere — does not exist yet.

## Source of truth (product spec)

Requisition Creation Agent — Signal 1 (PA Open Position). MVP. Spec is in Confluence; full text was pasted into the planning conversation. The agent does ALL business-rule evaluation (BR-UNI / BR-PA). Our subscription's only job: detect a valid trigger and POST.

## What shipped

**Files created:**
- `Product/Recruitment.Application.Services/EventSubscriptions/PositionAutomationPocEventSubscription.cs`
- `Product/Recruitment.Services.IntegratedTests.NetCore/EventSubscriptionTests/v2/PositionAutomationPocEventSubscriptionTests.cs`

**Files edited:**
- `Product/Recruitment.Infrastructure.Crosscutting/FeatureToggle/ToggleableFeature.cs` — added `PositionAutomationPOC` constant
- `Product/Recruitment.Application.Services/KafkaEventRegistry.cs` — registered subscription in PA consumer block
- `Product/Recruitment.EventService.NetCore/EventServiceBootstrapper.cs` — added DI registration via `RegisterType<...>().AsSelf()` to avoid DI conflict with existing `PositionChangedV2Event` subscribers

**Toggle:** `PositionAutomationPOC` — default OFF.

## Behavior

Subscribes to `PositionChangedV2Event` (covers 3 of 5 spec triggers: HEADCOUNT_APPROVAL_COMPLETED, On Hold→Open, Eliminated→Open). Inside `Process(payload)`:

1. Early return if `PositionAutomationPOC` toggle disabled
2. Load existing position from `IPositionRepository.Get(payload.PositionId)`
3. If `payload.Status == "Open"` AND stored position's status is NOT Open → POST to agent URL (default `http://xxx/agent`) with body `{ positionId: <guid> }`
4. HttpClient injected via constructor

Pattern follows `PositionChangedV2PayloadMapper.cs:124-147` (load from DB → field-level diff → act on change).

## Test situation — important

The integration test file **exists and compiles** but was **never confirmed to run green** in the current dev env (kenny ran into an apparent infra gap and pivoted to a unit test, which I rejected and removed; the unit test was moved to `/tmp` and is not in the commit).

So: **integration test is a compiled scaffold, not a proven green run.** Anyone picking this up should:
1. Try to run it via the building-and-testing skill / standard rec test flow
2. If infra is missing, diagnose what's needed (probably the same setup as sibling tests like `PositionAssignmentV2EventSubscriptionTests`)
3. Get it green before opening a real PR

## Out of scope (intentionally)

- All BR-UNI / BR-PA decision logic (the agent owns those)
- Brand-new-Open path via `PositionCreatedV2Event` / `PositionActivatedV2Event`
- Vacancy-from-departure path via `PositionUnAssignmentV2Event` (the assignment helper recomputes status to Open but does not signal a transition)
- Real agent URL / config plumbing — hardcoded fake URL for now
- Any decision logic — we trigger on the simplest "transitioned to Open" signal
- UI / controller / app run

## Open questions (carried forward — ask product / arch when picking back up)

1. **Agent URL & contract** — real endpoint, body shape, auth? Currently hardcoded to `http://xxx/agent`.
2. **HttpClient delivery** — direct `HttpClient` via constructor (POC choice) vs `IHttpClientFactory` vs a typed `IRequisitionAgentClient`? Production will likely want the typed-client path; see `MockPositionAutomationClient` for the pattern.
3. **Config source** — appsettings, service registry, tenant config? Not addressed in POC.
4. **Outbound payload shape** — currently sends just `{ positionId }`. Spec lists Key PA Fields the agent needs (Job Code, Position Title, Org Unit, Cost Center, Location, Hiring Manager, Approved Headcount, Position Type, FTE, Pay Grade, Event Source). Full enrichment is post-POC work.
5. **Other trigger paths** — to cover all 5 spec trigger types, additional subscriptions on `PositionCreatedV2Event` / `PositionActivatedV2Event` / `PositionUnAssignmentV2Event` are needed. Out of POC scope.
6. **OQ-BR-11 from spec** — "which PA event types are emitted on the same channel?" — codebase exploration confirmed our 5 PA events all flow through `KafkaConsumers.PositionAutomationKey` consumer group. Partial answer to the spec's open question.

## Templates / references for next person

- Subscription pattern: `PositionAssignedV2EventSubscription.cs`
- Field-diff pattern: `PositionChangedV2PayloadMapper.cs:124-147`
- Integration test base: `TestTenantBase`
- Test pattern (cleanest): `PositionAssignmentV2EventSubscriptionTests.cs`
- HTTP mock pattern: `MockHttpMessageHandler` (in `Recruitment.Tests.Common.NetCore`)
- HTTP mock usage example: `EnableBryteAIHeartBeatTests.cs`
- Typed-client mock pattern: `MockPositionAutomationClient`
- Status-derivation logic (where Open is computed today): `PositionAssignmentHelper.cs:73-87` and `PositionChangeDomainService.cs:434-454` — both compute new status but do NOT detect transitions

## Noise to ignore at repo root

These untracked files in the repo root are stale analysis docs from an earlier procrastination round (focused on a heartbeat event subscription, NOT this POC). Safe to `mv` to `/tmp`:
- `ANALYSIS_SUMMARY.md`
- `DELIVERABLES.txt`
- `README-ANALYSIS.md`
- `architecture-diagram.txt`
- `code-patterns-reference.md`
- `gap-analysis-position-automation-heartbeat.md`
- `position-automation-infrastructure-summary.txt`
- `status.json`

They are NOT in the commit and NOT relevant to the PA POC. Whoever picks this up should not get distracted by them.

## Handoff one-liner

Branch `poc/pa` has a dormant, toggle-gated subscription that detects PositionChanged → Open transitions and posts to a stubbed agent URL. Integration test compiles but hasn't been proven green. Pick up = run the test, decide whether to open PR as-is or enrich the payload first.
