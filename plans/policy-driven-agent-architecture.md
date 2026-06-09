# Policy-Driven Agent Architecture for Atlas

## Context

**What is Atlas?**
Atlas is an agentic Applicant Tracking System (ATS) that includes:
- Conversation-oriented Recruiter UI
- Task-performing agents
- Enhanced backend ATS capabilities

**The Challenge:**
We're building agents that need to respond differently based on customer-specific business rules. For example:
- Customer A: Auto-create requisition when cashier is terminated
- Customer B: Require VP approval when store manager is terminated
- Customer C: Never replace employees terminated for cause

We cannot hardcode every customer's unique workflow. We need a scalable way to define agent behavior that works across many customers and scenarios without becoming an unmaintainable N×M tangle of conditional logic.

**The Solution:**
Policy-driven agent architecture where agent behavior emerges from evaluating natural language policies against runtime context.

---

## Core Concept: Policy-Driven Sub-Agents

### What is a Policy?

A **policy** is a natural language statement that defines:
- **When** it applies (conditional matching)
- **What** action to take or information to gather
- **How** to handle the result

Policies come from two sources:
1. **Platform-defined** - Created by Atlas development team (non-negotiable guardrails, required data gathering)
2. **Customer-defined** - Created by tenant administrators (business-specific rules)

**Example policies:**
- Platform: "Check if an evergreen requisition exists for this position"
- Customer: "Always maintain an open requisition for cashier roles"
- Customer: "Require VP approval before opening manager requisitions"
- Platform: "Query HRIS API for terminated employee record"
- Customer: "Set salary budget to previous hire's salary plus 5%"

### What is a Sub-Agent?

A **sub-agent** is a specialized agent focused on one aspect of a larger workflow. Each sub-agent:
- Has a specific responsibility (e.g., "Determine if new req is necessary", "Populate requisition schema")
- Owns a set of policies
- Executes the standard policy evaluation pattern
- Returns control to its parent agent

**Example sub-agents for Requisition Creation:**
- Position Classifier - Gather info about terminated employee and their position
- Position Necessity - Determine if a new requisition should be created
- Requisition Schema - Identify what fields need to be filled on the requisition
- Field Population - Fill in each field according to policies

---

## The Policy Evaluation Pattern

Every sub-agent follows this execution pattern when invoked:

```
┌─────────────────────────────────────────────────────────┐
│ 1. INVOCATION                                           │
│    Parent agent calls sub-agent with current context    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 2. LOAD POLICY SET                                      │
│    - Retrieve platform-defined policies (hardcoded)     │
│    - Retrieve customer-defined policies (from registry) │
│    - All policies are natural language statements       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 3. RECONCILE POLICIES                                   │
│    - Apply predefined reconciliation rules              │
│    - Resolve conflicts deterministically                │
│    - Example: "Hard-coded policies override customer"   │
│    - Example: "Most specific policy wins"               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 4. MATCH AGAINST CONTEXT                                │
│    - Evaluate which policies apply to current state     │
│    - Check if we have sufficient information            │
│    - Identify missing data or conflicts                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 5. DECISION POINT                                       │
│    ┌─────────────────────────────────────────────────┐ │
│    │ Option A: Clear path + sufficient info          │ │
│    │ → ADVANCE to next agent                         │ │
│    └─────────────────────────────────────────────────┘ │
│    ┌─────────────────────────────────────────────────┐ │
│    │ Option B: Missing context information           │ │
│    │ → SAVE STATE + PAUSE                            │ │
│    │ → Identify what info is needed                  │ │
│    └─────────────────────────────────────────────────┘ │
│    ┌─────────────────────────────────────────────────┐ │
│    │ Option C: Cannot reconcile policies             │ │
│    │ → SAVE STATE + PAUSE                            │ │
│    │ → Explain conflict to human                     │ │
│    └─────────────────────────────────────────────────┘ │
│    ┌─────────────────────────────────────────────────┐ │
│    │ Option D: Policy explicitly says "pause"        │ │
│    │ → PAUSE (per business rule)                     │ │
│    └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Example: Requisition Creation Agent

### Parent Agent: Requisition Agent

Orchestrates the overall requisition creation flow by invoking sub-agents in sequence.

### Sub-Agent 1: Position Classifier

**Responsibility:** Gather information about the terminated employee and their position

**Policy Set (all platform-defined):**
- "Query HRIS API for employee record using employee_id from demand signal"
- "Query org chart for position details"
- "Extract job title, department, location, salary"

**Execution:**
- Load policies → Reconcile (no conflicts, all platform) → Match against context
- Decision: Have employee_id? Yes → Query APIs → Return enriched context
- Decision: Missing employee_id? → Pause: "Need employee_id to proceed"

**Output:** Context enriched with position details

---

### Sub-Agent 2: Position Necessity

**Responsibility:** Determine if a new requisition should be created

**Policy Set:**

Platform-defined:
- "Check if an evergreen requisition exists for this position"

Customer-defined:
- "Always maintain open requisition for cashier roles"
- "Require VP approval before opening manager requisitions"
- "Don't replace employees terminated for cause"

**Execution Example 1 (Cashier, Voluntary Termination):**

Context:
```
{
  "position": "Cashier",
  "termination_reason": "voluntary",
  "salary": "$35,000",
  "evergreen_req_exists": false
}
```

Evaluation:
1. Load policies (1 platform + 3 customer)
2. Reconcile: No conflicts
3. Match against context:
   - "Always maintain open req for cashier roles" → MATCHES
   - "Don't replace for cause" → Doesn't apply (voluntary term)
   - "Require VP approval for managers" → Doesn't apply (cashier)
   - "Evergreen req exists" → False
4. Decision: Clear directive to create requisition → **ADVANCE**

**Execution Example 2 (Manager, Unclear Budget):**

Context:
```
{
  "position": "Store Manager",
  "termination_reason": "voluntary",
  "salary": "$125,000",
  "evergreen_req_exists": false,
  "budget_approved": null
}
```

Evaluation:
1. Load policies
2. Reconcile: No conflicts
3. Match against context:
   - "Require VP approval for managers" → MATCHES
   - "Budget_approved" field is null
4. Decision: Need VP approval AND missing budget info → **PAUSE**
   - Message: "Need VP approval and budget information before proceeding"

---

### Sub-Agent 3: Requisition Schema

**Responsibility:** Identify what fields must be filled on the requisition

**Policy Set (all platform-defined):**
- "Load mandatory fields from ATS API contract (title, department, location, hiring_manager)"
- "Query tenant's PCF (People Configuration Fields) for custom fields"
- "Mark mandatory vs optional fields"

**Execution:**
- This is pure info-gathering, no customer policies
- Load API schema + tenant PCF config
- Return field list with requirements

**Output:** Schema definition
```
{
  "fields": [
    {"name": "job_title", "mandatory": true, "type": "string"},
    {"name": "department", "mandatory": true, "type": "string"},
    {"name": "salary_budget", "mandatory": true, "type": "currency"},
    {"name": "custom_cost_center", "mandatory": false, "type": "string"}
  ]
}
```

---

### Sub-Agent 4: Field Population (per field)

**Responsibility:** Determine how to populate each field in the schema

**Policy Set varies by field and customer:**

For `job_title`:
- Platform: "Use terminated employee's job title"

For `department`:
- Platform: "Use terminated employee's department"

For `salary_budget`:
- Customer A: "Set to previous hire's salary plus 5%"
- Customer B: "Set to average of last 3 hires in this position"
- Customer C: "Call Compensation Advisor sub-agent for recommendation"

For `hiring_manager`:
- Platform: "Use terminated employee's manager"
- Customer: "If manager is also terminated, use next level up"

**Execution Example (salary_budget for Customer A):**

Context:
```
{
  "previous_hire_salary": "$45,000",
  "position": "Cashier"
}
```

Evaluation:
1. Load policy: "Set to previous hire's salary plus 5%"
2. Match: Have previous_hire_salary? Yes
3. Calculation: $45,000 × 1.05 = $47,250
4. Decision: Have all info → **ADVANCE** with value

**Execution Example (salary_budget for Customer C):**

Context:
```
{
  "position": "Store Manager"
}
```

Evaluation:
1. Load policy: "Call Compensation Advisor sub-agent"
2. Match: Need recommendation
3. Decision: **INVOKE** Compensation Advisor sub-agent
4. Sub-agent returns recommendation OR pauses for market data
5. Continue based on sub-agent outcome

---

## Differentiation from Workflows

### Traditional Workflow (from Atlas → Signals → Workflows doc)

**Characteristics:**
- Predetermined sequence of steps
- Fixed guards at specific points
- Flow is designed ahead of time
- Executed by workflow engine following a plan

**Example:**
```
Step 1: Verify candidate email
  ↓
Step 2: HITL gate - recruiter approval
  ↓ (if approved)
Step 3: Create laptop request
  ↓
Step 4: Provision email account
```

### Policy-Driven Agent Architecture

**Characteristics:**
- Open-ended, emergent behavior
- Each sub-agent evaluates policies at runtime
- Flow adapts based on context and policies
- Pauses anywhere when info is missing or reconciliation needed

**Example:**
```
Requisition Agent
  ↓
Position Classifier (gather info)
  ↓
Position Necessity (evaluate policies → might pause)
  ↓ (if approved)
Requisition Schema (load config)
  ↓
Field Population (per field, might pause, might invoke sub-agents)
  ↓
(Continue based on context and policies...)
```

### When to Use Each

| Use Workflow When... | Use Policy-Driven Agent When... |
|---------------------|----------------------------------|
| Steps are known and fixed | Steps depend on context |
| Same sequence every time | Sequence varies by customer/scenario |
| Gates are at predetermined points | Pauses happen anywhere based on data availability |
| Compliance requires audit trail of exact steps | Flexibility is more important than predictability |

**Note:** The two patterns can coexist. A workflow might invoke a policy-driven agent as one of its steps.

---

## Policy Authoring & Validation

### How Customers Define Policies

**Authoring UX (Hybrid Approach):**

For each sub-agent that accepts customer-defined policies, the UI will:

1. **Show suggested action chips** - Pre-defined common patterns displayed as clickable chips
   - Example chips for salary budget:
     - "Use previous employee's budget"
     - "Find the most recent hire"
     - "Average last 3 hires in this position"
   - Example chips for approval rules:
     - "Require VP approval"
     - "Auto-approve under $100k"
     - "Route to department head"

2. **Allow free-form natural language** - Users can type their own policies instead of selecting chips

3. **Enable chip modification** - Users can select a chip and then modify it with additional natural language
   - Example: Select "Use previous employee's budget" → modify to "Use previous employee's budget plus 5% for inflation"

**Chip Library:**
- **System-defined per sub-agent** - Each sub-agent has its own curated chip set
- **Not user-customizable initially** - Customers cannot create their own chips (Phase 1)
- **Contextual** - Chips shown are specific to what the sub-agent does

### Policy Evaluator Agent

When a customer saves a policy, the **Policy Evaluator Agent** runs to validate it:

**What it checks:**
1. **Clarity** - Can we understand what this policy means?
2. **Conflict detection** - Does this conflict with existing policies for this sub-agent?
3. **Interpretability** - Can this be evaluated at runtime?
4. **Security** - Does this contain prompt injection or malicious instructions?

**Validation outcomes:**

| Issue Type | Action | Phase |
|-----------|--------|-------|
| **Prompt injection detected** | **Reject** - Block saving entirely | Phase 1 |
| **Unclear policy** | **Reject** - Block until clarified | Phase 1 |
| **Conflicts with existing policy** | **Reject** - Show conflict, user must resolve | Phase 1 |
| **Valid policy** | **Accept** - Save to policy registry | Phase 1 |
| **Suggestions for improvement** | Offer corrections (future capability) | Phase 2+ |

**Security guardrails (Prompt-hacking prevention):**
- Detects attempts to override system instructions
- Blocks policies with embedded commands or escape sequences
- Flags suspicious patterns (e.g., "ignore all previous instructions")
- **Action on detection:** Reject policy entirely with explanation

### Policy Conflict Resolution During Authoring

When Policy Evaluator detects a conflict between user-defined policies:

**User must manually reconcile:**
1. See both conflicting policies side-by-side
2. Choose to:
   - Delete one of the policies
   - Modify one or both to remove conflict
   - Assign explicit priority order (which should evaluate first)

**Example conflict:**
- Policy 1: "Never replace employees in Q4 (hiring freeze)"
- Policy 2: "Always maintain open cashier reqs (high turnover)"
- Context: Cashier terminated in November
- **User action required:** Either remove one, modify to make them compatible, or set priority

**System-defined policies cannot be modified or deleted** - they always apply and override user policies.

---

## Policy Reconciliation Rules

When multiple policies could apply at runtime, the agent uses deterministic rules to resolve conflicts.

### Confirmed Reconciliation Hierarchy

1. **System-defined policies ALWAYS apply** (non-negotiable, cannot be overridden)
   - Security guardrails
   - Compliance requirements
   - Required data gathering
   - Platform technical constraints

2. **User-defined policies evaluated in priority order**
   - Users can set explicit priority when creating policies
   - Most recently defined policy wins if no explicit priority set

3. **Explicit "pause" policies take precedence**
   - If any applicable policy says "pause for approval", the agent pauses
   - Even if other policies say "proceed automatically"

4. **Fall-through: If ambiguous or conflicting → Pause for human**
   - If reconciliation cannot produce a clear directive
   - If required context is missing
   - Default safe behavior: ask a human

### Example Reconciliation Scenarios

**Scenario 1: Compatible policies**

Store Manager termination

**Policies:**
- System: "Check evergreen req" (info gathering)
- User (tenant-wide): "Always maintain open reqs for all positions"
- User (role-specific, priority 1): "Require VP approval for manager positions"

**Reconciliation:**
1. System policy applies (always): Check evergreen req → none found
2. User policies both apply
3. They're compatible: "Create req" + "Get approval first"
4. Combined directive: "Create req, but pause for VP approval before posting"
5. **Decision:** Advance to schema creation, mark as "pending VP approval"

---

**Scenario 2: User policy conflicts**

Cashier terminated in November

**Policies:**
- System: "Check evergreen req"
- User (priority 1): "Never replace employees in Q4 (hiring freeze)"
- User (priority 2): "Always maintain open cashier reqs (high turnover)"

**Reconciliation:**
1. System policy applies: Check evergreen req → none found
2. User policy priority 1 says "don't create req"
3. User policy priority 2 says "create req"
4. Priority 1 wins → **Decision:** Don't create requisition (hiring freeze takes precedence)

*Note: If policies had no explicit priority, agent would pause and explain the conflict to a human.*

---

**Scenario 3: System policy overrides user policy**

Attempt to create requisition without budget approval

**Policies:**
- System: "All requisitions with salary > $100k require budget approval before creation"
- User: "Auto-create all manager requisitions immediately"

**Context:** Manager role, salary $125,000, no budget approval

**Reconciliation:**
1. System policy applies (non-negotiable): Salary > $100k → budget approval required
2. User policy says "auto-create"
3. **System policy ALWAYS wins**
4. **Decision:** Pause for budget approval (system policy enforced, user policy ignored for this case)

---

**Scenario 4: Ambiguous context → Pause**

Store Manager termination with unclear data

**Policies:**
- System: "Check evergreen req"
- User: "Require VP approval for manager positions with team size > 10"

**Context:** Manager role, team_size = null (missing data)

**Reconciliation:**
1. System policy applies: Check evergreen req
2. User policy requires team_size to evaluate
3. team_size is missing from context
4. Cannot determine if policy applies
5. **Decision:** Pause for human → "Need team size to determine if VP approval required"

---

## Design Decisions Made

### Policy Authoring
✅ **Hybrid UX** - Suggested chips (system-defined per sub-agent) + free-form natural language + chip modification

✅ **Chip library** - System-defined per sub-agent, not user-customizable initially

✅ **Policy Evaluator** - Validates clarity, conflicts, interpretability, and security before saving

✅ **Validation blocking** - Phase 1: Block saving until fixed; Phase 2+: Suggest corrections

### Security
✅ **Prompt-hacking detection** - Policy Evaluator scans for malicious instructions and rejects entirely if found

✅ **System policy override** - System-defined policies ALWAYS apply, cannot be modified or overridden by customers

### Conflict Resolution
✅ **User policy conflicts** - User must manually reconcile during authoring (delete, modify, or set priority)

✅ **Runtime reconciliation** - System policies first, then user policies in priority order, pause if ambiguous

---

## Open Technical Questions (Still TBD)

To implement this pattern, we still need to answer:

### 1. Policy Storage
- Where are policies stored? (Database? Policy registry service?)
- How are they versioned?
- How do we handle policy updates for in-flight agents?

### 2. Policy Evaluation Runtime
- Does the LLM evaluate policies at runtime for each sub-agent?
- Do we pre-compile policies into decision trees for performance?
- How do we ensure deterministic evaluation across invocations?

### 3. State Management
- How is state saved when pausing?
- What's the serialization format for context?
- Where is paused state stored (database, queue, cache)?
- How long do we retain paused state before timeout?

### 4. Context Passing
- What format does context use between sub-agents? (JSON? Structured object?)
- How is sensitive data handled (PII, salary info, SSNs)?
- What's the maximum context size?
- Do we encrypt context in transit and at rest?

### 5. Observability & Audit
- How do we log which policies were evaluated?
- How do we explain why an agent paused (which policy triggered it)?
- What audit trail exists for policy-driven decisions?
- Do we show policy evaluation details in the Recruiter Hub?

### 6. Integration with Workflow Engine
- How do policy-driven agents interact with deterministic workflows?
- Can a workflow step invoke a policy-driven agent?
- Can a policy-driven agent create a workflow as its output?
- Where's the handoff point between agent and workflow?

### 7. Performance & Scalability
- If every sub-agent invocation loads and evaluates policies via LLM, what's the latency impact?
- Can we cache policy evaluations for identical contexts?
- What's the throughput limit (agents/second)?

### 8. Sub-Agent Reusability
- Can sub-agents be shared across parent agents? (e.g., Position Classifier used by both Requisition Agent and Talent Pool Agent)
- If shared, do they inherit different policies based on parent context?

### 9. Testing
- How do we test policy evaluation?
- Can we simulate context to verify policy matching?
- What's the testing strategy for policy combinations?

---

## Relationship to Atlas → Signals → Workflows Architecture

### Where Policy-Driven Agents Fit

The Atlas → Signals → Workflows document describes:
- **Signal Router** - matches signals to workflows via TriggerBindings
- **Workflows** - predetermined sequences executed by platform
- **Skills** - reusable capabilities invoked by workflows

Policy-driven agents are a **new layer** that sits between signals and workflows:

```
Signal (HCM termination)
  ↓
Signal Router (matches to binding)
  ↓
Trigger Binding (points to Requisition Agent)
  ↓
POLICY-DRIVEN AGENT (Requisition Agent + sub-agents)
  ↓ (might create)
Workflow (if a deterministic process is needed)
  ↓ (invokes)
Skills (reusable tools)
```

### TriggerBinding with Policy Context

The TriggerBinding might look like:

```json
{
  "binding_id": "trg-req-on-termination",
  "tenant_id": "customer-a",
  "match": {
    "signal_type": "hcm.separation",
    "condition": "termination_reason is voluntary or retirement"
  },
  "target": {
    "type": "policy_driven_agent",
    "ref": "requisition_agent",
    "agent_version": 3
  },
  "input_mapping": {
    "employee_id": "from signal.employee_id",
    "termination_reason": "from signal.reason"
  },
  "policy_context": {
    "tenant_policies": ["policy-set-customer-a-v12"],
    "autonomy": "recruiter_supervised"
  }
}
```

### Execution Flow Integration

1. **Signal arrives** → Signal Router matches binding
2. **Dispatcher invokes** policy-driven agent (not a workflow)
3. **Agent executes** using policy evaluation pattern
4. **Agent might pause** → updates view store → shows in Recruiter Hub
5. **Recruiter provides input** → directed command resumes agent
6. **Agent completes** → might trigger a workflow OR create ATS records directly
7. **Outcome event** → Output Handler updates view store

### Key Differences from Workflows

| Aspect | Workflows (from doc) | Policy-Driven Agents |
|--------|---------------------|----------------------|
| Structure | Pre-planned steps | Emergent from policies |
| Execution | Platform workflow engine | Agent runtime (LLM-based?) |
| Pausing | At predetermined HITL gates | Anywhere, based on context |
| Customization | Per workflow version | Per policy set |
| Determinism | High (same inputs → same path) | Lower (LLM interpretation) |

---

## Next Steps

To move this concept forward with the other team:

1. **Validate the pattern**: Does this match their understanding of agent architecture?
2. **Define policy schema**: What does a policy actually look like (syntax, structure)?
3. **Choose reconciliation rules**: Agree on the hierarchy for conflict resolution
4. **Pick storage approach**: Where do policies live and how are they managed?
5. **Design state management**: How do we save/resume when pausing?
6. **Build PoC**: Implement one sub-agent (e.g., Position Necessity) end-to-end
7. **Define integration points**: How does this connect to the Signal Router and Workflow Engine?
