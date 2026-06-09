# Policy-Driven Agent Architecture for Atlas ATS

## Executive Summary

The system implements a hierarchical event-driven agent framework where autonomous agents evaluate runtime policies (platform + customer-defined) to make determinations about operational behavior. Position Automation is the proving ground: when a PA event arrives, a parent agent routes it through specialized sub-agents (Position Classifier, Position Necessity Evaluator, Requisition Schema Mapper, Field Population) that pause/advance/invoke requisition creation based on dynamic policy evaluation. This trades upfront policy compilation for runtime flexibility—agents use LLM reasoning or pre-compiled decision trees to match context against rules.

---

## 1. System Components & Dependency Graph

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SIGNAL ROUTER (Kafka)                             │
│                  PositionChangedV2Event → PositionChangedV2Payload        │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │ Event Subscription │
                    │ (PositionAutomation)
                    └─────────┬─────────┘
                              │
        ┌─────────────────────▼──────────────────────┐
        │ Requisition Agent (Parent/Orchestrator)    │
        │  - Policy Context Builder                 │
        │  - Sub-agent Executor                      │
        │  - Pause State Manager                     │
        │  - Decision Logger                         │
        └──────────────┬───────────────┬─────────────┘
                       │               │
         ┌─────────────▼┐    ┌────────▼──────────────┐
         │Sub-Agents    │    │State & Registry Svc   │
         ├─────────────┤    ├──────────────────────┤
         │Classifier   │    │Policy Registry        │
         │Necessity    │    │Context Store          │
         │Schema Map   │    │Pause State (MongoDB)  │
         │Populator    │    │Idempotency Log        │
         └─────────────┘    └────────┬──────────────┘
                                     │
                            ┌────────▼────────┐
                            │Workflow Engine  │
                            │ (Async Invoke)  │
                            └─────────────────┘
```

**Component Roles:**

| Component | Responsibility | Tech |
|-----------|-----------------|------|
| Signal Router | Kafka topic consumption, event deserialization | Plata.Eventing.Kafka |
| Event Subscription | Decision to invoke agent (toggle + validation) | IAsyncEventSubscription |
| Parent Agent | Orchestrate sub-agents, manage state transitions | Stateless + call graph |
| Sub-agents | Policy evaluation, context extraction, determination | Decision tree or LLM |
| Policy Registry | Store/retrieve platform + tenant policies | MongoDB collection |
| Context Store | Build context snapshot for agent reasoning | Domain models |
| Pause State Store | Track agent pauses, idempotency keys, status | MongoDB collection |
| Idempotency Log | Prevent duplicate requisition creation | MongoDB collection + Redis |
| Workflow Engine | Fire-and-forget async job submission | Background job queue |

---

## 2. Data Models

### 2.1 Policy Schema (Flexible, Versioned)

```csharp
namespace Recruitment.Domain.Model.PolicyDriven;

public class PolicyDefinition
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string PolicyName { get; set; }  // "position-necessity-classifier"
    public string PolicyVersion { get; set; }  // "1.0"
    public PolicyScope Scope { get; set; }  // Platform | Tenant
    public PolicyType Type { get; set; }  // Classifier | Necessity | SchemaMap | FieldPopulation
    
    // Either serialized decision tree OR prompt template for LLM
    public PolicyEvaluationModel EvaluationModel { get; set; }  // DecisionTree | LLMPrompt
    public string DecisionTreeJson { get; set; }  // Pre-compiled rules
    public string LLMPromptTemplate { get; set; }  // For runtime eval
    
    public Dictionary<string, PolicyParameter> Parameters { get; set; }  // Thresholds, weights
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastUpdatedAt { get; set; }
    public int VersionNumber { get; set; }
}

public enum PolicyScope { Platform, Tenant }
public enum PolicyType { Classifier, Necessity, SchemaMap, FieldPopulation }
public enum PolicyEvaluationModel { DecisionTree, LLMPrompt, Hybrid }

public class PolicyParameter
{
    public string Name { get; set; }
    public object DefaultValue { get; set; }
    public string Type { get; set; }  // "int", "string", "bool", "datetime"
    public string Description { get; set; }
}
```

### 2.2 Context Schema (Agent Input)

```csharp
public class PolicyEvaluationContext
{
    public Guid TenantId { get; set; }
    public Guid PositionId { get; set; }
    public Guid? CorrelationId { get; set; }  // For idempotency
    
    // Position state from event
    public string PositionCode { get; set; }
    public string PositionStatus { get; set; }  // Open, Filled, On Hold, etc.
    public string PositionTitle { get; set; }
    public string PreviousStatus { get; set; }  // For status-change triggers
    public DateTime? StatusChangeTimestamp { get; set; }
    
    // Org context
    public Guid? HiringManagerId { get; set; }
    public Guid? OrgLevel1Id { get; set; }
    public Guid? OrgLevel2Id { get; set; }
    public Guid? OrgLevel3Id { get; set; }
    public Guid? CostCenterId { get; set; }
    public Guid? WorkLocationId { get; set; }
    
    // PA fields
    public decimal ApprovedHeadcount { get; set; }
    public decimal CurrentHeadcount { get; set; }
    public string PositionType { get; set; }
    public decimal FTE { get; set; }
    public string PayGrade { get; set; }
    public string JobCode { get; set; }
    
    // Policy overrides/flags
    public Dictionary<string, object> TenantPolicyParameters { get; set; }
    public DateTime EventReceivedAt { get; set; }
    
    // Historical for 24h freeze check
    public List<PositionStatusHistory> RecentStatusChanges { get; set; }
}

public class PositionStatusHistory
{
    public string FromStatus { get; set; }
    public string ToStatus { get; set; }
    public DateTime ChangedAt { get; set; }
}
```

### 2.3 Pause State Format (Agent Execution State)

```csharp
public class AgentPauseState
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid PositionId { get; set; }
    public Guid CorrelationId { get; set; }  // Unique per event/position combo
    
    // Which agents have executed
    public Dictionary<string, SubAgentExecutionRecord> SubAgentExecutions { get; set; }
    
    // Why paused
    public PauseReason PauseReason { get; set; }  // PolicyEvalFailure, ManualHold, ValidationError
    public string PauseMessage { get; set; }
    public List<PolicyEvaluationResult> FailedPolicyEvaluations { get; set; }
    
    // How to resume
    public PauseType PauseType { get; set; }  // Blocking | NonBlocking | Manual
    public DateTime? ResumeAfter { get; set; }  // For time-based pauses
    public Dictionary<string, object> ResumeContext { get; set; }  // What changed
    
    // Tracking
    public int ExecutionAttempts { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastModifiedAt { get; set; }
    public PauseStateStatus Status { get; set; }  // Active | Resolved | Expired | Abandoned
}

public enum PauseReason { PolicyEvalFailure, ManualHold, ValidationError, ThrottleLimit }
public enum PauseType { Blocking, NonBlocking, Manual }
public enum PauseStateStatus { Active, Resolved, Expired, Abandoned }

public class SubAgentExecutionRecord
{
    public string AgentName { get; set; }
    public string Version { get; set; }
    public DateTime ExecutedAt { get; set; }
    public AgentDecision Decision { get; set; }  // Pass | Fail | Error
    public object Result { get; set; }
    public List<PolicyEvaluationResult> PolicyResults { get; set; }
    public int DurationMs { get; set; }
}

public enum AgentDecision { Pass, Fail, Error, Deferred }
```

### 2.4 Policy Registry Structure

```csharp
public interface IPolicyRegistry
{
    // Retrieve compiled policy for evaluation
    Task<PolicyDefinition> GetPolicyAsync(
        Guid tenantId,
        string policyName,
        string version = "latest");
    
    // Get tenant overrides (overwrite platform defaults)
    Task<PolicyDefinition> GetTenantPolicyAsync(
        Guid tenantId,
        string policyName);
    
    // List all applicable policies for a tenant + policy type
    Task<List<PolicyDefinition>> GetApplicablePoliciesAsync(
        Guid tenantId,
        PolicyType type);
    
    // Upsert policy (platform ops or tenant admin)
    Task UpsertPolicyAsync(PolicyDefinition policy);
    
    // Audit: get policy change history
    Task<List<PolicyDefinition>> GetPolicyHistoryAsync(
        string policyName,
        Guid? tenantId = null);
}
```

---

## 3. Key APIs (Component Contracts)

### 3.1 Policy Storage API

```csharp
public interface IPolicyStore
{
    // Write policy (audit changes)
    Task<Result> StorePolicyAsync(PolicyDefinition policy);
    
    // Read with fallback to platform default
    Task<Result<PolicyDefinition>> GetPolicyAsync(
        Guid tenantId,
        string policyName,
        string version);
    
    // Bulk load for agent startup
    Task<Result<List<PolicyDefinition>>> GetPoliciesByTypeAsync(
        Guid tenantId,
        PolicyType type);
}
```

### 3.2 Policy Evaluator API

```csharp
public interface IPolicyEvaluator
{
    // Main decision point: does context match policy?
    Task<PolicyEvaluationResult> EvaluateAsync(
        PolicyDefinition policy,
        PolicyEvaluationContext context);
}

public class PolicyEvaluationResult
{
    public bool Matches { get; set; }  // true = policy applies
    public double Confidence { get; set; }  // [0.0, 1.0] for ML
    public string Explanation { get; set; }  // Why matched/not
    public Dictionary<string, object> ExtractedFields { get; set; }  // For mappers
    public List<string> AppliedRules { get; set; }  // Which rules fired
    public DateTime EvaluatedAt { get; set; }
}
```

### 3.3 Runtime Reconciliation API

```csharp
public interface IRuntimeReconciliator
{
    // Main flow: load policies → evaluate context → decide → record state
    Task<Result<AgentDecision>> ReconcileAsync(
        PolicyEvaluationContext context,
        List<PolicyDefinition> applicablePolicies);
}

// Reconciliation flow:
// 1. Load: Fetch all active policies for (tenantId, policyType)
// 2. Reconcile: Match context against each policy (in priority order)
// 3. Match: First policy to match determines decision
// 4. Decide: Pass (continue) | Fail (pause) | Error (retry or dead-letter)
```

### 3.4 State Manager API

```csharp
public interface IAgentStateManager
{
    // Pause execution
    Task<Result> PauseAsync(AgentPauseState state);
    
    // Retrieve for resume
    Task<Result<AgentPauseState>> GetPauseStateAsync(
        Guid tenantId,
        Guid positionId,
        Guid correlationId);
    
    // Resume after manual intervention or condition met
    Task<Result> ResumeAsync(
        Guid tenantId,
        Guid positionId,
        Guid correlationId,
        Dictionary<string, object> resumeContext);
    
    // Garbage collect expired/abandoned pauses
    Task<int> ExpirePausesAsync(int olderThanDays = 30);
    
    // Idempotency check
    Task<bool> HasProcessedAsync(
        Guid tenantId,
        Guid positionId,
        Guid correlationId);
}
```

### 3.5 Sub-Agent Executor API

```csharp
public interface ISubAgentExecutor
{
    // Execute a single agent (Classifier, Necessity, etc.)
    Task<Result<AgentDecision>> ExecuteAsync(
        string agentName,
        PolicyEvaluationContext context,
        List<PolicyDefinition> agentPolicies);
}
```

---

## 4. Reconciliation Engine (Load → Reconcile → Match → Decide)

```csharp
public class RuntimeReconciliationEngine : IRuntimeReconciliator
{
    private readonly IPolicyStore policyStore;
    private readonly IPolicyEvaluator evaluator;
    private readonly IAgentStateManager stateManager;
    private readonly IPlataLogger logger;

    public async Task<Result<AgentDecision>> ReconcileAsync(
        PolicyEvaluationContext context,
        List<PolicyDefinition> applicablePolicies)
    {
        // PHASE 1: LOAD
        // Fetch platform default + tenant override policies
        var policies = await LoadPoliciesAsync(context.TenantId);
        
        if (policies.Count == 0)
        {
            logger.Warn()
                .Message("No policies found for tenant")
                .Property("TenantId", context.TenantId)
                .Write();
            return AgentDecision.Error;  // Fail safe: no policy = no action
        }

        // Check idempotency: have we already processed this event?
        var alreadyProcessed = await stateManager.HasProcessedAsync(
            context.TenantId,
            context.PositionId,
            context.CorrelationId);
        
        if (alreadyProcessed)
        {
            logger.Info()
                .Message("Duplicate event detected, skipping")
                .Property("CorrelationId", context.CorrelationId)
                .Write();
            return AgentDecision.Pass;  // Idempotent: succeed silently
        }

        // PHASE 2: RECONCILE (Priority order)
        var results = new List<PolicyEvaluationResult>();
        var prioritizedPolicies = policies.OrderBy(p => p.Priority).ToList();

        foreach (var policy in prioritizedPolicies)
        {
            var result = await evaluator.EvaluateAsync(policy, context);
            results.Add(result);
            
            logger.Debug()
                .Message("Policy evaluated")
                .Property("PolicyName", policy.PolicyName)
                .Property("Matches", result.Matches)
                .Property("Confidence", result.Confidence)
                .Write();

            // PHASE 3: MATCH (first match wins)
            if (result.Matches)
            {
                // PHASE 4: DECIDE
                var decision = DetermineAction(result, policy);
                
                // Record state
                await RecordDecisionAsync(context, decision, results);
                
                return decision;
            }
        }

        // No policies matched: fail safe (pause, don't create requisition)
        logger.Info()
            .Message("No policies matched, pausing agent")
            .Property("PositionId", context.PositionId)
            .Write();
        
        return AgentDecision.Fail;
    }

    private async Task<List<PolicyDefinition>> LoadPoliciesAsync(Guid tenantId)
    {
        // Try tenant override first, fall back to platform
        var tenantPolicies = await policyStore.GetPoliciesByTypeAsync(
            tenantId, PolicyType.Necessity);
        
        if (tenantPolicies.Result?.Count > 0)
            return tenantPolicies.Result;

        // Fall back to platform default
        var platformPolicies = await policyStore.GetPoliciesByTypeAsync(
            Guid.Empty, PolicyType.Necessity);  // Guid.Empty = platform
        
        return platformPolicies.Result ?? new List<PolicyDefinition>();
    }

    private AgentDecision DetermineAction(
        PolicyEvaluationResult policyResult,
        PolicyDefinition policy)
    {
        // Policy action determines agent behavior
        if (policyResult.Confidence < policy.Parameters["min_confidence"].DefaultValue)
            return AgentDecision.Deferred;
        
        return AgentDecision.Pass;  // Proceed to next agent
    }

    private async Task RecordDecisionAsync(
        PolicyEvaluationContext context,
        AgentDecision decision,
        List<PolicyEvaluationResult> results)
    {
        // Audit log: which policies evaluated, which matched, decision taken
        var record = new SubAgentExecutionRecord
        {
            AgentName = "RuntimeReconciler",
            Decision = decision,
            ExecutedAt = DateTime.UtcNow,
            PolicyResults = results,
            DurationMs = (int)(DateTime.UtcNow - context.EventReceivedAt).TotalMilliseconds
        };
        
        // Store if paused
        if (decision == AgentDecision.Fail)
        {
            var pauseState = new AgentPauseState
            {
                Id = Guid.NewGuid(),
                TenantId = context.TenantId,
                PositionId = context.PositionId,
                CorrelationId = context.CorrelationId,
                PauseReason = PauseReason.PolicyEvalFailure,
                FailedPolicyEvaluations = results,
                CreatedAt = DateTime.UtcNow,
                Status = PauseStateStatus.Active
            };
            
            await stateManager.PauseAsync(pauseState);
        }
    }
}
```

---

## 5. State Management

### 5.1 Storage Strategy

**MongoDB Collections:**

```
tenant-{tenantId}
├─ policies (PolicyDefinition)
│   ├─ index: { policyName, version, isActive }
│   ├─ index: { tenantId, policyType }
│   └─ audit trail: { policyName, versionNumber, createdAt }
│
├─ agent-pause-states (AgentPauseState)
│   ├─ index: { tenantId, positionId, correlationId } [UNIQUE]
│   ├─ index: { tenantId, status, createdAt } [for GC queries]
│   └─ index: { correlationId } [for idempotency]
│
├─ idempotency-log (IdempoencyRecord)
│   ├─ index: { tenantId, positionId, correlationId } [UNIQUE]
│   └─ ttl: 30 days (auto-expire)
│
└─ agent-execution-audit (SubAgentExecutionRecord)
    ├─ index: { tenantId, positionId, createdAt }
    └─ retention: 90 days
```

### 5.2 Resume Flow

```csharp
public class ResumeOrchestrator
{
    private readonly IAgentStateManager stateManager;
    private readonly ISubAgentExecutor executor;

    // Triggered by: manual intervention, time-based schedule, webhook
    public async Task ResumeAsync(
        Guid tenantId,
        Guid positionId,
        Guid correlationId)
    {
        // Fetch paused state
        var pauseState = await stateManager.GetPauseStateAsync(
            tenantId, positionId, correlationId);
        
        if (pauseState.Result == null)
            return;  // Already resolved or expired

        // Re-evaluate with fresh context
        var freshContext = await BuildContextAsync(tenantId, positionId);
        var policies = await policyStore.GetPoliciesByTypeAsync(tenantId, PolicyType.Necessity);
        
        // Re-run reconciliation
        var decision = await reconciler.ReconcileAsync(freshContext, policies.Result);
        
        if (decision.IsSuccess && decision.Result == AgentDecision.Pass)
        {
            // Mark pause as resolved
            await stateManager.ResumeAsync(tenantId, positionId, correlationId, new());
        }
    }
}
```

### 5.3 Garbage Collection

```csharp
// Heartbeat (runs daily, off-peak)
public class ExpirePauseStatesHeartBeat
{
    public async Task Execute()
    {
        var expiredCount = await stateManager.ExpirePausesAsync(olderThanDays: 30);
        logger.Info()
            .Message("Expired old pause states")
            .Property("Count", expiredCount)
            .Write();
    }
}
```

---

## 6. Determinism Strategy: LLM vs Decision Trees

### Trade-offs

| Dimension | LLM Reasoning | Pre-Compiled Decision Tree |
|-----------|--------------|--------------------------|
| **Flexibility** | Very high; handles novel contexts | Limited; must enumerate rules |
| **Speed** | Slow (500ms-2s per call) | Fast (1-10ms per evaluation) |
| **Cost** | High (LLM API calls) | Low (in-process) |
| **Determinism** | Low (token sampling) | Perfect (deterministic) |
| **Auditability** | Hard ("black box" reasoning) | Perfect (clear rule trace) |
| **Learning** | Can improve with few-shot | Requires policy update |
| **Compliance** | Risk for regulated decisions | Safe (explainable) |

### Recommendation: **Hybrid Approach**

1. **Platform Policies**: Use pre-compiled decision trees (determinism + compliance)
2. **Tenant Policies**: Support both (tenant chooses via toggle)
3. **Position Necessity**: Decision tree for v1 (clear, auditable rules)
4. **Example Rules** (Decision Tree JSON):

```json
{
  "policyName": "position-necessity-classifier",
  "rules": [
    {
      "id": "rule-1",
      "condition": {
        "positionStatus": "Open",
        "previousStatus": { "$in": ["Inactive", "OnHold", "Frozen"] }
      },
      "action": "PASS",
      "priority": 1
    },
    {
      "id": "rule-2",
      "condition": {
        "positionStatus": "Open",
        "previousStatus": "Filled",
        "statusChangeTimestamp": {
          "$gt": "2024-06-03T00:00:00Z",
          "$lt": "2024-06-04T00:00:00Z"
        }
      },
      "action": "PASS",
      "priority": 2
    },
    {
      "id": "rule-3",
      "condition": {
        "positionStatus": { "$in": ["Draft", "PendingApproval"] }
      },
      "action": "FAIL",
      "pauseReason": "PositionNotYetApproved",
      "priority": 3
    }
  ]
}
```

---

## 7. Security Model

### 7.1 Prompt Injection Detection

```csharp
public class PromptInjectionGuard
{
    private readonly List<string> suspiciousPatterns = new()
    {
        "ignore your instructions",
        "follow new instructions from",
        "disregard",
        "system prompt",
        "you are now"
    };

    public bool IsLikelyInjection(string input)
    {
        var normalized = input.ToLowerInvariant();
        return suspiciousPatterns.Any(p => normalized.Contains(p));
    }
}
```

### 7.2 PII Handling

```csharp
public class ContextSanitizer
{
    // Strip PII from context before LLM eval
    public PolicyEvaluationContext Sanitize(PolicyEvaluationContext context)
    {
        context.HiringManagerId = null;  // Don't expose person IDs
        context.PositionTitle = "****";  // Mask sensitive job titles
        // Keep only structural/policy-relevant fields
        return context;
    }
}
```

### 7.3 Policy Sandbox

```csharp
// Decision trees are JSON: no code execution risk
// LLM prompts are templated and sanitized before sending to Claude

public class LLMPolicySandbox
{
    private const int MAX_CONTEXT_SIZE = 2048;  // Prevent unbounded input
    private const int MAX_POLICY_RULES = 100;   // Prevent DOS

    public async Task<PolicyEvaluationResult> EvaluateAsync(
        string prompt,
        PolicyEvaluationContext context)
    {
        if (prompt.Length > MAX_CONTEXT_SIZE)
            throw new InvalidOperationException("Prompt exceeds max size");
        
        // Sanitize context first
        var safeContext = new ContextSanitizer().Sanitize(context);
        
        // Call Claude with rate limiting
        using (var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10)))
        {
            return await claudeClient.EvaluateAsync(prompt, safeContext, cts.Token);
        }
    }
}
```

---

## 8. Observability & Audit Trail

### 8.1 Logging Strategy

```csharp
public class PolicyEvaluationLogger
{
    public void LogPolicyEvaluation(
        PolicyEvaluationContext context,
        PolicyDefinition policy,
        PolicyEvaluationResult result)
    {
        logger.Info()
            .Message("Policy evaluated")
            .Property("TenantId", context.TenantId)
            .Property("PositionId", context.PositionId)
            .Property("CorrelationId", context.CorrelationId)
            .Property("PolicyName", policy.PolicyName)
            .Property("PolicyVersion", policy.PolicyVersion)
            .Property("Matches", result.Matches)
            .Property("Confidence", result.Confidence)
            .Property("Explanation", result.Explanation)
            .Property("AppliedRules", string.Join(",", result.AppliedRules))
            .Property("DurationMs", result.EvaluatedAt)
            .Write();
    }

    public void LogAgentDecision(
        PolicyEvaluationContext context,
        AgentDecision decision,
        List<PolicyEvaluationResult> results)
    {
        logger.Info()
            .Message("Agent decision rendered")
            .Property("TenantId", context.TenantId)
            .Property("PositionId", context.PositionId)
            .Property("Decision", decision)
            .Property("PolicyCount", results.Count)
            .Property("MatchCount", results.Count(r => r.Matches))
            .Write();
    }
}
```

### 8.2 Audit Trail

```csharp
// Every policy evaluation + agent decision is immutable in MongoDB
public class AuditTrail
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid PositionId { get; set; }
    public Guid CorrelationId { get; set; }
    public string EventType { get; set; }  // PolicyEvaluated | AgentDecision | Paused | Resumed
    public object Details { get; set; }  // Full snapshot
    public DateTime TimestampUtc { get; set; }
    public string Actor { get; set; }  // System | UserId
}

// Query: "Show me all policy evals that led to position X being paused"
// Query: "Tenant Y: which policies are blocking position requisition creation?"
```

---

## 9. Integration Points

### 9.1 Signal Router → Agent Entry Point

```csharp
public class PositionAutomationEventSubscription : IAsyncEventSubscription<PositionChangedV2Event, PositionChangedV2Payload>
{
    private readonly IRequisitionAgent agent;
    private readonly ITenantFeatureToggle featureToggle;
    private readonly IIdempotencyChecker idempotencyChecker;

    public async Task Process(PositionChangedV2Payload payload)
    {
        // Guard: toggle
        if (!featureToggle.IsEnabled(ToggleableFeature.EnableReqCreationAgent))
            return;

        // Guard: idempotency
        var correlationId = IdempotencyKeyGenerator.Generate(payload);
        if (await idempotencyChecker.HasProcessedAsync(payload.TenantId, payload.PositionId, correlationId))
            return;

        // Build context from payload
        var context = new PositionAutomationContextBuilder().Build(payload);
        
        // Invoke agent
        var decision = await agent.EvaluateAsync(context);
        
        // Decision → Action
        if (decision == AgentDecision.Pass)
        {
            // Queue async workflow job
            await workflowEngine.QueueAsync(
                new CreateRequisitionWorkflowJob(payload.TenantId, payload.PositionId));
        }
        else if (decision == AgentDecision.Fail)
        {
            // Paused: audit logged by agent, signal retry strategy
            logger.Info().Message("Requisition creation paused by policy").Write();
        }
    }
}
```

### 9.2 Agent → Workflow Engine (Fire-and-Forget)

```csharp
public interface IWorkflowEngine
{
    // Queue job for async processing (e.g., Hangfire, Kubernetes Job)
    Task QueueAsync(WorkflowJob job);
}

public class CreateRequisitionWorkflowJob : WorkflowJob
{
    public Guid TenantId { get; set; }
    public Guid PositionId { get; set; }
    public Guid CorrelationId { get; set; }
    
    public override async Task ExecuteAsync()
    {
        // Call Bryte Supervisor Agent to create requisition
        // This is fire-and-forget from PA agent perspective
        var result = await bryteAgent.InitiateRequisitionAsync(TenantId, PositionId);
        // Log result, handle retries via job framework
    }
}
```

---

## 10. Implementation Roadmap

### Phase 1: PoC (Position Necessity Classifier Only) — 6 weeks

**Goal:** Prove policy-driven pattern on simplest use case.

**Deliverables:**
- [ ] PolicyDefinition schema + MongoDB collection
- [ ] DecisionTreeEvaluator (JSON rules → boolean)
- [ ] RuntimeReconciliationEngine (load → reconcile → match → decide)
- [ ] AgentPauseState store + GC
- [ ] Unit tests (decision tree eval, reconciliation flow)
- [ ] Integration test (event → pause state written)

**Effort:** 3 devs × 2 weeks = 6 person-weeks
**Risk:** None; isolated, no breaking changes. Uses existing event subscription pattern.

**Code Skeleton:**
```
Recruitment.Domain/
├─ Model/PolicyDriven/
│  ├─ PolicyDefinition.cs
│  ├─ PolicyEvaluationContext.cs
│  ├─ AgentPauseState.cs
│  └─ *.cs (other models)
│
Recruitment.Application.Services/
├─ PolicyEngine/
│  ├─ IDecisionTreeEvaluator.cs
│  ├─ DecisionTreeEvaluator.cs
│  ├─ IPolicyStore.cs
│  ├─ PolicyStore.cs
│  ├─ RuntimeReconciliationEngine.cs
│  └─ *.cs (managers, loggers)
│
Recruitment.Persistence.Migrations/
└─ {timestamp}_CreatePolicyDefinitionsCollection.cs
```

---

### Phase 2: MVP (4 Sub-agents + Tenant Policies) — 8 weeks

**Goal:** Full agent ecosystem with tenant policy overrides.

**Adds:**
- [ ] Position Classifier agent (sub-agent #1)
- [ ] Position Necessity agent (sub-agent #2)
- [ ] Requisition Schema Mapper agent (sub-agent #3)
- [ ] Field Population agent (sub-agent #4)
- [ ] Parent orchestrator (calls sub-agents in sequence)
- [ ] Tenant policy override UI (admin panel)
- [ ] Policy change tracking (audit log)
- [ ] Resume flow (manual intervention recovery)
- [ ] System tests (end-to-end: event → requisition draft)

**Effort:** 4 devs × 2 weeks = 8 person-weeks
**Risk:** Sub-agent coordination; resume logic correctness.

**Critical Path:**
1. Finalize sub-agent contracts
2. Implement parent orchestrator call graph
3. Test pause/resume state machine
4. Build admin UI for policy edits

---

### Phase 3: Full Platform (LLM Support, Analytics, Scalability) — 12 weeks

**Goal:** Production-ready, supports LLM policies, tenant self-service.

**Adds:**
- [ ] Claude/LLM evaluator (alternative to decision trees)
- [ ] Policy versioning + rollback
- [ ] Tenant policy sandbox (rate limits, input validation)
- [ ] Analytics dashboard (policy eval success rate, pause reasons)
- [ ] Self-service policy editor (UI for tenants)
- [ ] Batch pause recovery (cron job + webhooks)
- [ ] Scalability: async agent execution (Kubernetes jobs)
- [ ] Multi-tenant policy hierarchy (company-level → department-level)

**Effort:** 5 devs × 2.4 weeks = 12 person-weeks
**Risk:** LLM cost, token consumption, latency SLA.

---

## 11. Effort Estimate & Timeline

### Phased Breakdown

| Phase | Duration | FTE | Key Risk | Mitigation |
|-------|----------|-----|----------|-----------|
| **PoC** | 6 weeks | 3 | Schema design paralysis | Finalize in sprint 0 (2 days) |
| **MVP** | 8 weeks | 4 | Sub-agent coordination | Mock sub-agents first (1 week) |
| **Full** | 12 weeks | 5 | LLM latency / cost | Benchmark Claude latency early (week 1) |
| **Total** | 26 weeks | ~4 avg | | |

### Critical Path (Longest dependency chain)

```
Sprint 0 (2 days)
├─ Finalize PolicyDefinition schema
├─ Design MongoDB collections
└─ Plan DecisionTreeEvaluator format

↓ (Week 1-2: PoC Foundation)
Sprint 1-2 (PoC phase 1)
├─ Implement PolicyStore + queries
├─ Build DecisionTreeEvaluator
└─ Write unit tests

↓ (Week 3-6: PoC Integration & Phase 2 Start)
Sprint 3-6 (PoC phase 2 + MVP phase 1)
├─ Integrate event subscription
├─ Build AgentStateManager
├─ Start parent orchestrator
└─ Begin sub-agent contracts

↓ (Week 7-13: MVP Completion)
Sprint 7-13 (MVP phase 2 + Phase 3 start)
├─ Sub-agent implementations
├─ Resume flow
├─ Admin policy UI
└─ LLM evaluator (async track)

↓ (Week 14-26: Full Platform Hardening)
Sprint 14-26 (Phase 3 completion)
├─ Analytics dashboard
├─ Scalability improvements
├─ Performance optimization
└─ Production readiness
```

**Go-live readiness:** End of MVP (Week 14) with Phase 3 features behind toggles.

---

## 12. Risk Factors & De-risking

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|-----------|
| **Policy schema too rigid** | Rework on tenant feedback | Medium | PoC phase: gather tenant feedback on schema before MVP |
| **Sub-agent coordination bugs** | Deadlocks, inconsistent state | Medium | Mock sub-agents + state machine tests (week 4) |
| **LLM latency (full platform)** | SLA miss (>5s event processing) | High | Benchmark Claude + implement request timeout (week 15) |
| **LLM cost overrun** | Budget exceeded | Medium | Implement caching + hybrid (DT for common cases, LLM for edge) |
| **Idempotency failures** | Duplicate requisitions created | High | Correlation ID + MongoDB unique index + tests (PoC) |
| **Pause state garbage collection** | DB bloat | Low | Implement TTL index on creation date (Phase 1) |
| **Policy eval audit data explosion** | Disk I/O, query slowdown | Medium | Implement retention policy (90 days) + archival (week 18) |

---

## 13. Success Metrics

### Phase 1 (PoC)
- Decision tree evaluator executes in <10ms
- 0 duplicate requisitions created (idempotency 100%)
- 100% unit test coverage for evaluator + reconciler

### Phase 2 (MVP)
- End-to-end latency: <1s (event → agent decision)
- Pause state accuracy: 99% (correct pause reasons)
- Tenant policy override working for ≥2 pilot customers

### Phase 3 (Full)
- LLM evaluator <500ms latency (p95)
- Cost per evaluation: <$0.01 (batching + caching)
- Dashboard: policy eval success rate >95%

---

## Conclusion

This architecture separates **policy definition** (data) from **policy evaluation** (logic), enabling runtime flexibility without redeployment. The reconciliation engine's "load → reconcile → match → decide" pattern is deterministic and auditable, critical for compliance. Phased rollout manages risk: PoC proves the pattern, MVP scales to 4 agents, Phase 3 adds LLM optionality for advanced tenants.

**Key technical wins:**
- Policies as first-class data (MongoDB stored, versioned, tenant-overridable)
- Sub-agent contract clarity (each agent = one policy matcher)
- Idempotency + pause state = safe retry semantics
- Hybrid LLM/decision tree = flexibility without sacrificing auditability

**Next immediate steps:**
1. Finalize PolicyDefinition schema (sprint 0)
2. Implement DecisionTreeEvaluator (sprint 1)
3. Gather tenant feedback on policy customization (during PoC)
