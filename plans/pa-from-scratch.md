# PA from Scratch — Kafka Consumer Reference

For someone rebuilding the **Requisition Creation Agent — Signal 1 (PA Open Position)** OUTSIDE the recruiting C# codebase. Could be Java, Python, Node — doesn't matter. This doc tells you what topics to subscribe to, what's in the payloads, and what business logic the recruiting code does on top of the framework so you know what you have to recreate.

The recruiting app uses an internal framework called **Plata.Eventing** that wraps Confluent.Kafka. Outside the monolith, you don't have Plata. You'd use vanilla Kafka client libraries (`confluent-kafka-python`, `kafka-clients` for Java, `kafkajs` for Node, etc.).

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

You'd pick your own group name (e.g. `req-agent.signal1.open-position`) so you don't fight recruiting for offsets. Each consumer group sees every message independently.

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

Both the recruiting Plata stack and an external consumer see the **same JSON on the wire**. The C# class names are recruiting's local types — the payload structure is what matters across languages.

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
- `Status` (string) — **the field we key on. Values include "Open", "Filled", "PartiallyFilled", "Inactive", "Active", "Closed", "Proposed", "Overstaffed"**
- `IsApproved` (bool)
- `IsApprovedDeleted` (bool?)
- `IsOverStaffingAllowed` (bool)
- `Notes` (string)
- `JobId` (Guid?)
- `ReportsToPositionId` (Guid?) — closest thing to "hiring manager" but it's another position, not a person
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
| Position ID | `position.id` | ✅ `PositionId` | ✅ `Id` |
| Job Title | `position.jobTitle` / `jobProfile.title` | ✅ `Name` | ✅ `LocalizedName` |
| Job Code | `position.jobCode` | ✅ `Code` | ✅ `Code`, `JobCode` |
| Job Profile ID | `position.jobProfile.id` | ✅ `JobId` | ❌ |
| Job Family | `position.jobFamily` | ❌ | ❌ |
| Job Level | `position.jobLevel` | ❌ | ❌ |
| Business Unit | `org.businessUnit` | ⚠️ Implicit (top OrgLevel ID) | ✅ Implicit (OrgLevels hierarchy) |
| Department | `org.department` | ⚠️ ID only | ✅ Resolved name in `OrgLevels[]` |
| **Cost Center** | `org.costCenter` | ❌ | ❌ |
| **Hiring Manager** | `position.reportsTo → person.id` | ❌ (`ReportsToPositionId` is a position, not a person) | ❌ |
| HRBP | `org.hrbp` | ❌ | ❌ |
| Location | `position.location.id` + `.name` | ⚠️ `WorkLocationId` only | ✅ Id, Name, City, State, Country |
| Sub-location / Work Site | `position.workSite` | ❌ | ❌ |
| **Pay Grade** | `compensation.payGrade` | ❌ | ❌ |
| Pay Band (min/mid/max) | `compensation.payRange.*` | ❌ | ❌ |
| Pay Frequency | `compensation.payFrequency` | ❌ | ❌ |
| Currency | `compensation.currency` | ⚠️ `AmountPerFteCurrencyCode` (FTE rate only) | ❌ |
| **FLSA Status** | `jobProfile.flsaStatus` | ❌ | ❌ |
| EEO Category | `jobProfile.eeoCategory` | ❌ | ❌ |
| Worker Type | `position.workerType` | ❌ | ❌ |
| Employment Type | `position.employmentType` | ❌ | ❌ |
| OFCCP Flag | `org.ofccpCovered` | ❌ | ❌ |
| Bargaining Unit | `position.bargainingUnit` | ❌ | ❌ |
| FTE | `position.fte` | ✅ `FullTimeEquivalent` | ✅ `FTE` |
| Scheduled Hours | `position.scheduledHours` | ❌ | ❌ |
| Work Arrangement | `position.workArrangement` | ❌ | ❌ |
| Shift Type | `position.shiftType` | ✅ `ShiftCode` | ❌ |
| Travel Requirements | `jobProfile.travelRequirement` | ❌ | ❌ |
| **Approved Headcount** | (PA-side, not in spec PF section) | ❌ | ❌ |
| Change Reason / Source | (PA event source) | ✅ `ChangeReason`, `ChangeDetails` | ❌ |

**Bold rows are spec-required for approval AND not in any recruiting data source.** They have to come from People Fabric or another Core HR integration — regardless of whether the listener lives inside or outside recruiting.

### 5e. Required-for-Approval source matrix

The spec's Data Completeness Rules list 11 fields as Required for Approval. If the agent can't get them, the draft becomes Partial. Source for each:

| Required field | Best source | Risk for the agent |
|---|---|---|
| Job title | Kafka `Name` (or PF `position.jobTitle`) | 🟢 Low — in payload |
| Job code | Kafka `Code` | 🟢 Low — in payload |
| Location | PF `position.location.name` or recruiting ES | 🟡 Medium — needs lookup |
| Hiring manager | PF `position.reportsTo → person.id` | 🔴 High — only PF has it |
| Pay grade | PF `compensation.payGrade` | 🔴 High — only PF |
| Cost center | PF `org.costCenter` | 🔴 High — only PF |
| Org level / department | Recruiting ES `OrgLevels[]` (resolved) or PF | 🟡 Medium — ES helps |
| FLSA status | PF `jobProfile.flsaStatus` | 🔴 High — only PF |
| FTE type | Derived from Kafka `FullTimeEquivalent` | 🟢 Low |
| Number of openings / headcount | PF approved headcount | 🔴 High — Kafka has FTE only |
| Req type | Inferred from signal (PA = New Hire) per BR-PA-05 | 🟢 Low — derivable |

**Of 11 required fields, 5 require a People Fabric integration** the listener does NOT provide. The listener can honestly only assert "open position detected, here's the ID." The agent owns the PF lookups to fill the draft (which is exactly what BR-PA-04 expects).

### 5f. Spec open questions partially answered by this analysis

- **OQ-BR-11** ("Which PA event types are emitted on the same channel?") — partially answered: all PA events flow through the `position-automation` consumer key, but recruiting splits them into two consumer groups (`PositionAutomation` and `FlexDataAnalytics`). The 5 spec triggers map to events on 2 different topics (`position-snapshots` and `entity-position-dev`). A listener that wants full coverage subscribes to both.
- **OQ-BR-12** ("What People Fabric fields are reliably populated vs. commonly null?") — not answerable from recruiting code alone. Requires production data sampling against People Fabric. The matrix in 5d shows what fields exist in the schema, not their fill rate.
- **OQ-BR-03** ("Match criteria for existing open req — job code + location? job code + cost center? position ID?") — recruiting's ES indexes both `JobCode` and `Location.Id`, so job-code + location match is queryable. Cost center is not in ES, so cost-center match would require a separate Mongo or Core HR query.

## 6. What recruiting DOES on top of the framework

This is the part you have to reimplement in your generic listener. The recruiting C# code does this for the POC trigger:

```
1. Plata deserializes Kafka message → PositionChangedV2Payload object
2. Subscription's Process(payload) runs:
   a. Check tenant feature toggle (POC stays dormant)
   b. Load the previously-stored position from local Mongo
   c. Diff: payload.Status == "Open" AND stored.Status != Open
   d. If transition detected → POST { positionId } to agent URL
```

Source: `PositionAutomationPocEventSubscription.cs` (~120 lines).

**Important:** the payload itself does NOT tell you "this is a transition". It tells you the new state only. Detecting the transition requires comparing against last-known state — which means your generic listener also needs a small datastore (Redis, DB, anything) keyed by `PositionId` to remember each position's last `Status`.

## 7. Translating to a vanilla Kafka listener

Distance from "what recruiting has" to "vanilla Kafka consumer in $LANGUAGE": **small**. Most of the recruiting code is framework boilerplate you don't need.

### What Plata does for us (and you don't need to recreate)

- Topic name resolution (env prefix + JSON config overrides)
- Consumer group fully-qualified-name building
- Offset commit / retry / dead-letter routing
- Autofac DI for subscription instances
- Multi-tenant context propagation
- Logging (`IPlataLogger`)
- Toggle gating (`ITenantFeatureToggle`)

You replace those with: standard Kafka client config + your app's own logger / config / DI / toggle layer.

### What you DO need to write

1. **Kafka consumer** in $LANGUAGE pointing at:
   - Bootstrap servers: same as recruiting's (ask infra; recruiting reads from `RecruitingConfiguration.cs:1045-1098`)
   - Topic: `{env}.business-events.flex-data-analytics.entity-position-dev` (or prod equivalent)
   - Consumer group: yours, not recruiting's
   - Auth: probably SASL — check with Kafka platform team
2. **JSON deserialization** of the payload. The wire format is JSON. Define a class/struct/dict matching section 4 above. You can ignore fields you don't care about.
3. **Last-known-status store** — tiny key-value store: `PositionId → last Status`. Anything works (Redis, Postgres, even an in-mem map for POC).
4. **Transition detection** — same logic as `PositionAutomationPocEventSubscription.cs`:
   ```
   if payload.Status == "Open" and store.get(payload.PositionId) != "Open":
       post_to_agent({"positionId": payload.PositionId})
   store.set(payload.PositionId, payload.Status)
   ```
5. **Outbound HTTP POST** to the agent.

### Rough size estimate

A Python `confluent-kafka` consumer doing all of the above is **~80-120 lines** including config + retries. Java with `kafka-clients` is ~150-200 lines. None of this is hard — the work is operational (auth, networking, observability), not algorithmic.

### Caveats for going outside recruiting

- **Schema drift:** payload is owned by FlexDataAnalytics, not recruiting. If they change the schema, you're affected the same way recruiting is. Subscribe to their schema-change announcements.
- **Multi-tenancy:** `TenantId` is in the payload. You're on the hook for filtering by tenant if your agent is tenant-aware.
- **Volume:** every position field change publishes a message. Recruiting receives a LOT. Plan for backpressure.
- **Replay / startup state:** when your consumer first starts with a fresh group, it reads from the topic's earliest or latest offset depending on config. "Earliest" replays history (could be huge); "latest" misses everything before startup. Pick deliberately.

## 8. Summary for your hater conversation

- Recruiting is just one of N consumers on these topics. You can be another.
- The data you need to detect "position became Open" is in the payload **except** for transition history (you keep your own).
- The recruiting C# subscription does ~30 lines of real logic. Everything else is framework wiring.
- Going language-agnostic costs you nothing — the wire format is JSON, the topic is shared, the consumer-group model isolates you from recruiting.
- The fields the spec calls "Key PA Fields" are mostly in the payload (Job Code, Title, FTE, Org Units, Location). What's missing (Cost Center, Hiring Manager, Pay Grade, Approved Headcount) requires separate lookups regardless of where you implement the listener.

## 9. Reference files in this repo (if you can read them)

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
