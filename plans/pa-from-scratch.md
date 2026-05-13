# PA from Scratch — Kafka Consumer Reference

This document is for a team rebuilding the **Requisition Creation Agent — Signal 1 (PA Open Position)** outside the recruiting C# codebase, in any language (Java, Python, Node, etc.). It documents the Kafka topics to subscribe to, the payload shapes, and the business logic the recruiting code performs on top of its event framework so the equivalent work can be reproduced elsewhere.

The recruiting application uses an internal framework called **Plata.Eventing** that wraps Confluent.Kafka. Outside this codebase, Plata is not available. A vanilla Kafka client library (`confluent-kafka-python`, `kafka-clients` for Java, `kafkajs` for Node, etc.) would be used in its place.

---

## 1. The Kafka topics

All PA-related topics are prefixed with an environment string (`development`, `staging`, `production`, etc.):

| Logical name | Actual topic (dev) | Carries |
|---|---|---|
| Position snapshots | `development.business-events.position-automation.position-snapshots` | Position activated/inactivated |
| Position assignment snapshots | `development.business-events.position-automation.position-assignment-snapshots` | FTE assigned/unassigned |
| Tenant snapshots | `development.business-events.position-automation.tenant-provisioning-tenant-snapshots` | Tenant provisioning |
| **Flex DA entity-position** | `development.business-events.flex-data-analytics.entity-position-dev` | **Position field changes (the one we use for the POC)** |
| Flex DA entity-position-assignment | `development.business-events.flex-data-analytics.entity-position-assignment-dev` | Assignment field changes |

Topic constants live in `Product/Recruitment.Domain/Kafka/KafkaTopics.cs`. The `-dev` suffix on the Flex topics is **part of the topic name** in non-prod, not a typo.

**For the open-position signal, the topic to consume is `flex-data-analytics.entity-position-dev` (or its prod equivalent).**

## 2. Consumer groups

Recruiting registers all PA subscriptions under one logical consumer key `position-automation`. The full consumer group name is computed at runtime:

```
{KafkaEnvironment}.recruiting.rec-event.position-automation
```

A separate consumer group name (for example `req-agent.signal1.open-position`) should be chosen so the new consumer does not share offsets with the recruiting consumer. Each consumer group receives every message independently.

Defined: `Product/Recruitment.Domain/Kafka/KafkaConsumers.cs:50-67`

## 3. The events recruiting subscribes to

Listed in `Product/Recruitment.Application.Services/KafkaEventRegistry.cs:112-158`.

| Event class | Topic | Payload class |
|---|---|---|
| `PositionActivatedV2Event` | position-snapshots | `PositionActivatedV2Payload` |
| `PositionInactivatedV2Event` | position-snapshots | `PositionInactivatedV2Payload` |
| `TenantProvisioningTenantChangedV2Event` | tenant-snapshots | `TenantProvisioningTenantChangedV2Payload` |
| `PositionAssignmentV2Event` | position-assignment-snapshots | `PositionAssignmentV2Payload` |
| `PositionUnAssignmentV2Event` | position-assignment-snapshots | `PositionAssignmentV2Payload` |
| **`PositionChangedV2Event`** | **entity-position-dev** | **`PositionChangedV2Payload`** ← POC uses this |
| `PositionAssignedV2Event` | entity-position-assignment-dev | `PositionAssignedV2Payload` |
| `PositionFlexAssignedV2Event` | entity-position-assignment-dev | `PositionAssignedV2Payload` |
| `PositionFlexChangedV2Event` | entity-position-dev | `PositionChangedV2Payload` |

Both the recruiting Plata stack and an external consumer see the same JSON on the wire. The C# class names are recruiting's local types; the payload structure is what is portable across languages.

## 4. PositionChangedV2Payload — every field

This is the one the POC consumes. From `Product/Recruitment.Domain/Events/v2/Payloads/PositionAutomation/PositionChangedV2Payload.cs` plus its base classes.

**Inherited (`PositionBaseV2Payload` + `BasePayload`):**
- `EffectiveVersionId` (Guid)
- `TenantId` (Guid)
- `PositionId` (Guid)
- `TransactionState` (string)
- `EffectiveStartDate`, `EffectiveEndDate`, `EffectiveStartDateTime`, `EffectiveEndDateTime` (DateTime?)
- `InactivatedBy` (Guid?), `InactivatedAt` (DateTime?)
- `CreatedBy` (Guid?), `CreatedDateTime` (DateTime?)
- `UpdatedBy` (Guid?), `UpdatedDateTime` (DateTime?)
- `RowVersion` (int)
- `ExtensionData` (object)

**Own fields:**
- `Code` (string) — position code / job code
- `Name` (string) — position title
- `AlternativePositionNumber` (string)
- `FullTimeEquivalent` (decimal) — FTE
- `Status` (string) — **the field on which the POC's transition rule is evaluated. Possible values include "Open", "Filled", "PartiallyFilled", "Inactive", "Active", "Closed", "Proposed", "Overstaffed"**
- `IsApproved` (bool)
- `IsApprovedDeleted` (bool?)
- `IsOverStaffingAllowed` (bool)
- `Notes` (string)
- `JobId` (Guid?)
- `ReportsToPositionId` (Guid?) — the closest equivalent to "hiring manager" available in the payload, but it references another position, not a person
- `BudgetId` (Guid?)
- `AmountPerFte` (decimal?), `AmountPerFteCurrencyCode` (string)
- `BudgetEndDate` (DateTime?)
- `CompanyId` (Guid?) — legal entity
- `OrgLevel1OrganizationUnitId` … `OrgLevel4OrganizationUnitId` (Guid?) — 4 nested org levels
- `WorkLocationId` (Guid?)
- `ProjectCode` (string)
- `ShiftCode` (string)
- `ChangeReason` (string) — useful for figuring out trigger source
- `ChangeDetails` (string)
- `DefaultLocaleCode` (string)
- `Translations` (List<PositionTranslationDto>) — localized name/notes

### What's missing from the payload

Per the spec's "Key PA Fields", these are **not** in the payload and would need separate lookups against UKG Pro / Core HR:
- Cost Center
- Hiring Manager (real person, not `ReportsToPositionId`)
- Pay Grade
- Approved Headcount (only FTE is in payload)
- Resolved names for Org Unit / Location / Company / Job (only IDs are in payload)

### What Elasticsearch covers

Recruiting indexes a `SearchablePosition` document into ES. It helps with **some** of the gaps above — specifically the resolved names — but NOT the truly-missing business fields.

Indexed in ES (`Product/Recruitment.Domain/SearchModel/Position/SearchablePosition.cs`, mapping at `Product/Recruitment.Persistence/Search/Mapping/SearchablePositionMapping.cs`):

- `Id`, `Code`, `LocalizedName`, `JobCode`, `Status` (name + enum byte), `FTE`, `TenantId`
- **`OrgLevels[]`** — each with `Id`, `Code`, `Description`, `CategoryName`, `Level` ← **resolved org names**
- **`Location`** — `Id`, `Name`, `City`, `State` (name+code), `Country` (localized name + code) ← **resolved location names**

So if the agent wants human-readable Org Unit / Location strings, ES is a viable source for those (via `SearchablePositionRepository`).

**Still NOT in ES** (would need UKG Pro / Core HR lookup):
- Cost Center
- Hiring Manager (no manager / owner field at all)
- Pay Grade / salary band
- Approved Headcount (FTE is indexed, not headcount)
- Resolved Company name
- Resolved Job name (only `JobCode`, no `JobName`)

**Bottom line:** Kafka payload + ES together cover names for Org Unit and Location, but the four spec fields (Cost Center, Hiring Manager, Pay Grade, Approved Headcount) aren't anywhere in recruiting's data — they live in upstream HR systems and need a separate integration regardless of where the listener runs.

## 5. Cross-reference with the product spec (May 2026)

Product owner Jennifer Perez maintains the authoritative spec for the Requisition Creation Agent (BR-UNI / BR-PA / BR-TERM / BR-WFM / BR-SEA rules + People Fabric field reference). This section reconciles what's in this repo against that spec.

### 5a. Five spec triggers vs what our POC catches

The spec lists 5 PA event types that qualify as Signal 1 triggers:

| Spec trigger | Spec event | Status transition | Our Kafka coverage |
|---|---|---|---|
| New position opened | `POSITION_CREATED` | → Open or Approved for Hire | `PositionActivatedV2Event` (NOT in POC) |
| Vacancy from departure | `POSITION_STATUS_CHANGED` | Filled → Open | `PositionUnAssignmentV2Event` recomputes status via `PositionAssignmentHelper:73-87` but emits no transition signal (NOT covered) |
| Headcount approval completed | `HEADCOUNT_APPROVAL_COMPLETED` | Pending Approval → Approved for Hire | `PositionChangedV2Event` (POC catches via Status field) |
| Reopened from hold/freeze | `POSITION_STATUS_CHANGED` | On Hold/Frozen → Open | `PositionChangedV2Event` (POC catches) |
| Reactivated from elimination | `POSITION_STATUS_CHANGED` | Eliminated → Open | `PositionChangedV2Event` (POC catches) |

**POC covers 3 of 5.** Full coverage requires also subscribing to `PositionActivatedV2Event` and a workaround for the vacancy-from-departure case (assignment helper recomputes status to Open but does not emit a transition).

### 5b. What does NOT trigger (per spec)

A vanilla listener should filter these out — log and skip:

- Status → Draft or Pending Approval (not yet authorized)
- Status → On Hold / Frozen (intentionally suppressed)
- Status → Filled (just filled, not open)
- Status → Eliminated / Closed (removed, not to be filled)
- Field update with no Status change (metadata correction)
- Position transferred to a different manager (org change, not hiring signal)
- Position created with Status = Filled (retroactive data entry)

Our POC's `was-not-Open AND is-now-Open` rule handles most of these naturally. The "field update only" case is also handled — the transition test fails when Status didn't change.

### 5c. The agent owns the business logic — the listener does NOT

The spec defines 10 universal checks (BR-UNI) and 5 PA-specific checks (BR-PA). **None are the listener's responsibility.** They run inside the agent, after the listener POSTs.

Examples the listener intentionally ignores:

- BR-UNI-04 Suppression list
- BR-UNI-05 Evergreen role check
- BR-UNI-06 Existing open req check
- BR-UNI-07 Budget cap → Tier 2 routing
- BR-UNI-08 Hiring freeze
- BR-UNI-09 RIF / layoff pattern detection
- BR-UNI-10 Active labor action / strike
- BR-PA-01 Existing req linked to position ID
- BR-PA-02 Batch headcount grouping

The listener's contract is intentionally narrow: **detect a valid trigger, POST `{ positionId }` to the agent.** The agent does everything else.

### 5d. People Fabric field reference (where the agent reads non-Kafka data)

The spec's "People Fabric: Position Data Field Reference" section maps each agent-required field to a People Fabric (UKG Core HR) JSON path. **When PA and People Fabric carry the same field, People Fabric is authoritative** per the spec.

Spec field → People Fabric path → in our Kafka payload? → in our ES?

| Spec field | People Fabric path | Kafka payload | Recruiting ES |
|---|---|---|---|
| Position ID | `position.id` | Yes — `PositionId` | Yes — `Id` |
| Job Title | `position.jobTitle` / `jobProfile.title` | Yes — `Name` | Yes — `LocalizedName` |
| Job Code | `position.jobCode` | Yes — `Code` | Yes — `Code`, `JobCode` |
| Job Profile ID | `position.jobProfile.id` | Yes — `JobId` | No |
| Job Family | `position.jobFamily` | No | No |
| Job Level | `position.jobLevel` | No | No |
| Business Unit | `org.businessUnit` | Partial — implicit (top OrgLevel ID) | Yes — implicit in OrgLevels hierarchy |
| Department | `org.department` | Partial — ID only | Yes — resolved name in `OrgLevels[]` |
| **Cost Center** | `org.costCenter` | No | No |
| **Hiring Manager** | `position.reportsTo → person.id` | No (`ReportsToPositionId` is a position, not a person) | No |
| HRBP | `org.hrbp` | No | No |
| Location | `position.location.id` + `.name` | Partial — `WorkLocationId` only | Yes — Id, Name, City, State, Country |
| Sub-location / Work Site | `position.workSite` | No | No |
| **Pay Grade** | `compensation.payGrade` | No | No |
| Pay Band (min/mid/max) | `compensation.payRange.*` | No | No |
| Pay Frequency | `compensation.payFrequency` | No | No |
| Currency | `compensation.currency` | Partial — `AmountPerFteCurrencyCode` (FTE rate only) | No |
| **FLSA Status** | `jobProfile.flsaStatus` | No | No |
| EEO Category | `jobProfile.eeoCategory` | No | No |
| Worker Type | `position.workerType` | No | No |
| Employment Type | `position.employmentType` | No | No |
| OFCCP Flag | `org.ofccpCovered` | No | No |
| Bargaining Unit | `position.bargainingUnit` | No | No |
| FTE | `position.fte` | Yes — `FullTimeEquivalent` | Yes — `FTE` |
| Scheduled Hours | `position.scheduledHours` | No | No |
| Work Arrangement | `position.workArrangement` | No | No |
| Shift Type | `position.shiftType` | Yes — `ShiftCode` | No |
| Travel Requirements | `jobProfile.travelRequirement` | No | No |
| **Approved Headcount** | (PA-side, not in spec PF section) | No | No |
| Change Reason / Source | (PA event source) | Yes — `ChangeReason`, `ChangeDetails` | No |

**Bold rows are spec-required for approval AND not in any recruiting data source.** They have to come from People Fabric or another Core HR integration — regardless of whether the listener lives inside or outside recruiting.

### 5e. Required-for-Approval source matrix

The spec's Data Completeness Rules list 11 fields as Required for Approval. If the agent can't get them, the draft becomes Partial. Source for each:

| Required field | Best source | Risk for the agent |
|---|---|---|
| Job title | Kafka `Name` (or PF `position.jobTitle`) | Low — present in payload |
| Job code | Kafka `Code` | Low — present in payload |
| Location | PF `position.location.name` or recruiting ES | Medium — requires a lookup |
| Hiring manager | PF `position.reportsTo → person.id` | High — only People Fabric has it |
| Pay grade | PF `compensation.payGrade` | High — only People Fabric |
| Cost center | PF `org.costCenter` | High — only People Fabric |
| Org level / department | Recruiting ES `OrgLevels[]` (resolved) or PF | Medium — ES provides resolved names |
| FLSA status | PF `jobProfile.flsaStatus` | High — only People Fabric |
| FTE type | Derived from Kafka `FullTimeEquivalent` | Low |
| Number of openings / headcount | PF approved headcount | High — Kafka carries FTE only |
| Req type | Inferred from signal (PA = New Hire) per BR-PA-05 | Low — derivable from trigger |

**Of 11 required fields, 5 require a People Fabric integration** the listener does NOT provide. The listener can honestly only assert "open position detected, here's the ID." The agent owns the PF lookups to fill the draft (which is exactly what BR-PA-04 expects).

### 5f. Spec open questions partially answered by this analysis

- **OQ-BR-11** ("Which PA event types are emitted on the same channel?") — partially answered: all PA events flow through the `position-automation` consumer key, but recruiting splits them into two consumer groups (`PositionAutomation` and `FlexDataAnalytics`). The 5 spec triggers map to events on 2 different topics (`position-snapshots` and `entity-position-dev`). A listener that wants full coverage subscribes to both.
- **OQ-BR-12** ("What People Fabric fields are reliably populated vs. commonly null?") — not answerable from recruiting code alone. Requires production data sampling against People Fabric. The matrix in 5d shows what fields exist in the schema, not their fill rate.
- **OQ-BR-03** ("Match criteria for existing open req — job code + location? job code + cost center? position ID?") — recruiting's ES indexes both `JobCode` and `Location.Id`, so job-code + location match is queryable. Cost center is not in ES, so cost-center match would require a separate Mongo or Core HR query.

## 6. What the recruiting code does on top of the framework

This is the portion that needs to be reproduced in any external listener. The recruiting C# code performs the following for the POC trigger:

```
1. Plata deserializes Kafka message → PositionChangedV2Payload object
2. Subscription's Process(payload) runs:
   a. Check tenant feature toggle (POC stays dormant)
   b. Load the previously-stored position from local Mongo
   c. Diff: payload.Status == "Open" AND stored.Status != Open
   d. If transition detected → POST { positionId } to agent URL
```

Source: `PositionAutomationPocEventSubscription.cs` (~120 lines).

**Important:** the payload itself does not signal a transition. It carries only the new state. Detecting a transition requires comparing the incoming state against the last-known state, which means an external listener needs a small datastore (Redis, a database table, etc.) keyed by `PositionId` to record each position's most recent `Status`.

## 7. Translating to a vanilla Kafka listener

The distance from the recruiting implementation to a vanilla Kafka consumer in any language is small. Most of the recruiting code is framework infrastructure that does not need to be reproduced.

### What Plata provides (and does not need to be reproduced)

- Topic name resolution (env prefix + JSON config overrides)
- Consumer group fully-qualified-name building
- Offset commit / retry / dead-letter routing
- Autofac DI for subscription instances
- Multi-tenant context propagation
- Logging (`IPlataLogger`)
- Toggle gating (`ITenantFeatureToggle`)

These can be replaced with a standard Kafka client configuration plus the host application's own logging, configuration, dependency injection, and feature toggle layers.

### What needs to be written

1. **Kafka consumer** in the chosen language, configured with:
   - Bootstrap servers — same brokers used by recruiting (confirm with the platform team; recruiting reads these from `RecruitingConfiguration.cs:1045-1098`)
   - Topic — `{env}.business-events.flex-data-analytics.entity-position-dev` (or production equivalent)
   - Consumer group — a new group, distinct from recruiting's
   - Authentication — likely SASL; confirm with the Kafka platform team
2. **JSON deserialization** of the payload. The wire format is JSON. Define a class, struct, or dictionary matching section 4 above. Fields not used by the agent can be ignored.
3. **Last-known-status store** — a small key-value store mapping `PositionId` to last seen `Status`. Redis, Postgres, or even an in-memory map is sufficient for a POC.
4. **Transition detection** — equivalent to the logic in `PositionAutomationPocEventSubscription.cs`:
   ```
   if payload.Status == "Open" and store.get(payload.PositionId) != "Open":
       post_to_agent({"positionId": payload.PositionId})
   store.set(payload.PositionId, payload.Status)
   ```
5. **Outbound HTTP POST** to the agent.

### Rough size estimate

A Python `confluent-kafka` consumer covering all of the above is roughly 80–120 lines, including configuration and retry handling. A Java implementation with `kafka-clients` is roughly 150–200 lines. The work is primarily operational (authentication, networking, observability) rather than algorithmic.

### Considerations when running outside recruiting

- **Schema drift.** The payload is owned by the FlexDataAnalytics team, not recruiting. Schema changes affect any consumer equally. Subscribe to their schema-change announcements.
- **Multi-tenancy.** `TenantId` is included in the payload. Tenant filtering is the consumer's responsibility if the agent is tenant-aware.
- **Volume.** Every position field change publishes a message. Recruiting consumes a high volume of these. Plan for backpressure.
- **Replay and startup state.** A consumer joining with a fresh group reads from either the earliest or latest topic offset depending on configuration. "Earliest" replays the full retained history; "latest" skips everything before startup. Choose deliberately.

## 8. Summary

- Recruiting is one of several consumers on these topics. An additional consumer can be added without affecting recruiting.
- The data needed to detect a "position became Open" event is present in the payload, with the exception of prior-state transition history, which the consumer maintains itself.
- The recruiting subscription contains roughly 30 lines of business logic. The remainder is framework wiring.
- A language-agnostic implementation carries no functional cost: the wire format is JSON, the topic is shared, and the consumer-group model isolates the new consumer from recruiting.
- The fields the spec labels "Key PA Fields" are largely present in the payload (Job Code, Title, FTE, Org Units, Location). The fields that are missing (Cost Center, Hiring Manager, Pay Grade, Approved Headcount) require separate lookups regardless of where the listener is implemented.

## 9. Reference files in this repository

| Concern | File |
|---|---|
| Topic constants | `Product/Recruitment.Domain/Kafka/KafkaTopics.cs` |
| Consumer key constants | `Product/Recruitment.Domain/Kafka/KafkaConsumers.cs` |
| Consumer group names | `Product/Recruitment.Domain/Kafka/KafkaConsumerGroups.cs` |
| Event registry (subscriptions) | `Product/Recruitment.Application.Services/KafkaEventRegistry.cs:112-158` |
| EventService bootstrapping | `Product/Recruitment.EventService.NetCore/EventServiceBootstrapper.cs:60-119` |
| Kafka config (env, topics, groups) | `Product/Recruitment.Infrastructure.Crosscutting/Configuration/RecruitingConfiguration.cs:1045-1098` |
| Payload classes | `Product/Recruitment.Domain/Events/v2/Payloads/PositionAutomation/` |
| Event classes | `Product/Recruitment.Domain/Events/v2/` |
| POC subscription | `Product/Recruitment.Application.Services/EventSubscriptions/PositionAutomationPocEventSubscription.cs` |
| Field-diff pattern | `Product/Recruitment.Application.Services/Mappers/PositionChangedV2PayloadMapper.cs:124-147` |
