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

## 5. What recruiting DOES on top of the framework

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

## 6. Translating to a vanilla Kafka listener

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

## 7. Summary for your hater conversation

- Recruiting is just one of N consumers on these topics. You can be another.
- The data you need to detect "position became Open" is in the payload **except** for transition history (you keep your own).
- The recruiting C# subscription does ~30 lines of real logic. Everything else is framework wiring.
- Going language-agnostic costs you nothing — the wire format is JSON, the topic is shared, the consumer-group model isolates you from recruiting.
- The fields the spec calls "Key PA Fields" are mostly in the payload (Job Code, Title, FTE, Org Units, Location). What's missing (Cost Center, Hiring Manager, Pay Grade, Approved Headcount) requires separate lookups regardless of where you implement the listener.

## 8. Reference files in this repo (if you can read them)

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
