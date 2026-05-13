# PA POC — Position Automation Open-Position Detection

## Status

Shipped to branch `poc/pa` behind a feature toggle (default off). Commit `ce02b31e502`. Draft PR: https://github.com/UKGEPIC/recruiting-app/pull/6170.

## Purpose

This POC supports an early customer conversation. Because customers have indicated they do not want opportunities created automatically, the implementation ships dormant behind a tenant toggle. The objective is to prove that the wiring exists to detect a "position became Open" event and call out to an external agent, without changing behavior in any production tenant.

The agent itself is a parallel POC owned by a different team and does not exist yet.

## Source of truth (product spec)

Requisition Creation Agent — Signal 1 (PA Open Position), MVP scope. The spec lives in Confluence and defines the BR-UNI / BR-PA business rules. The agent is responsible for all business-rule evaluation. This subscription's only responsibility is to detect a valid trigger and POST.

## What shipped

**Files added:**

- `Product/Recruitment.Application.Services/EventSubscriptions/PositionAutomationPocEventSubscription.cs`
- `Product/Recruitment.Services.IntegratedTests.NetCore/EventSubscriptionTests/v2/PositionAutomationPocEventSubscriptionTests.cs`

**Files edited:**

- `Product/Recruitment.Infrastructure.Crosscutting/FeatureToggle/ToggleableFeature.cs` — added `PositionAutomationPOC` constant
- `Product/Recruitment.Application.Services/KafkaEventRegistry.cs` — registered the subscription in the Position Automation consumer block
- `Product/Recruitment.EventService.NetCore/EventServiceBootstrapper.cs` — added DI registration via `RegisterType<...>().AsSelf()` to avoid a DI conflict with the existing `PositionChangedV2Event` subscribers

**Toggle:** `PositionAutomationPOC`, default off.

## Behavior

The subscription consumes `PositionChangedV2Event`, which covers 3 of the 5 trigger types defined in the spec: `HEADCOUNT_APPROVAL_COMPLETED`, On Hold → Open, and Eliminated → Open.

Inside `Process(payload)`:

1. Return early if the `PositionAutomationPOC` toggle is disabled.
2. Load the stored position from `IPositionRepository.Get(payload.PositionId)`.
3. If `payload.Status == "Open"` and the stored position's status is not Open, POST to the agent URL (default `http://xxx/agent`) with body `{ positionId: <guid> }`.
4. `HttpClient` is injected through the constructor.

The transition-detection pattern mirrors `PositionChangedV2PayloadMapper.cs:124-147` (load from the document store, field-level diff, act on the change).

## Test status

The integration test file compiles but has not yet been confirmed to run green in the development environment. Anyone picking this up should:

1. Run the test through the standard project test workflow.
2. If supporting infrastructure is missing, diagnose what is needed (likely the same setup used by sibling tests such as `PositionAssignmentV2EventSubscriptionTests`).
3. Confirm a green run before merging the PR.

## Out of scope

- All BR-UNI and BR-PA decision logic (owned by the agent)
- Brand-new-Open path via `PositionCreatedV2Event` / `PositionActivatedV2Event`
- Vacancy-from-departure path via `PositionUnAssignmentV2Event` (the assignment helper recomputes status to Open but does not signal a transition)
- Real agent URL and configuration plumbing (placeholder hardcoded)
- Any agent-side decision logic
- UI, controller, or application-level wiring

## Open questions

1. **Agent URL and contract.** Real endpoint, body shape, and authentication are not yet defined. Currently hardcoded to `http://xxx/agent`.
2. **HttpClient delivery.** Direct `HttpClient` via constructor (POC choice) vs. `IHttpClientFactory` vs. a typed `IRequisitionAgentClient`. The production implementation will likely use the typed-client pattern; see `MockPositionAutomationClient` as a reference.
3. **Configuration source.** Appsettings, service registry, or tenant config — not yet addressed.
4. **Outbound payload shape.** Currently sends `{ positionId }`. The spec lists "Key PA Fields" the agent needs (Job Code, Position Title, Org Unit, Cost Center, Location, Hiring Manager, Approved Headcount, Position Type, FTE, Pay Grade, Event Source). Full enrichment is post-POC work.
5. **Other trigger paths.** Covering all 5 spec triggers requires additional subscriptions on `PositionCreatedV2Event` / `PositionActivatedV2Event` / `PositionUnAssignmentV2Event`. Out of POC scope.
6. **OQ-BR-11 from spec** ("Which PA event types are emitted on the same channel?"). All 5 PA event types flow through the `PositionAutomationKey` consumer key, but recruiting splits them across two consumer groups in the event registry. This is a partial answer to the spec's open question.

## Templates and references

- Subscription pattern: `PositionAssignedV2EventSubscription.cs`
- Field-diff pattern: `PositionChangedV2PayloadMapper.cs:124-147`
- Integration test base: `TestTenantBase`
- Recommended test pattern: `PositionAssignmentV2EventSubscriptionTests.cs`
- HTTP mock pattern: `MockHttpMessageHandler` in `Recruitment.Tests.Common.NetCore`
- HTTP mock usage example: `EnableBryteAIHeartBeatTests.cs`
- Typed-client mock pattern: `MockPositionAutomationClient`
- Status-derivation logic (where Open is computed today): `PositionAssignmentHelper.cs:73-87` and `PositionChangeDomainService.cs:434-454`. Both compute the new status but do not detect transitions.

## Untracked analysis files at repo root

The following files exist at the repository root from earlier exploratory analysis on a separate topic (a heartbeat event subscription, not this POC). They are not part of the commit and are not relevant to the PA POC:

- `ANALYSIS_SUMMARY.md`
- `DELIVERABLES.txt`
- `README-ANALYSIS.md`
- `architecture-diagram.txt`
- `code-patterns-reference.md`
- `gap-analysis-position-automation-heartbeat.md`
- `position-automation-infrastructure-summary.txt`
- `status.json`

They can be removed or moved out of the working tree at any time.

## Summary

Branch `poc/pa` contains a dormant, toggle-gated subscription that detects PositionChanged → Open transitions and posts to a stubbed agent URL. The integration test compiles but has not yet been proven green. Next step for whoever picks this up: run the test, then decide whether to merge the PR as-is or enrich the outbound payload first.
