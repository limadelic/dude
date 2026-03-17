# Enigma Intent Training

## What

Register ProPeopleApplicationAgent in the Bryte ecosystem so the SDK can route to it.

## BryteHub

https://brytehub.suitex-search-dev.dlas1.ucloud.int

## Steps

### 1. Agent in BryteHub ✅

Agent exists, 20 training examples, deployed as v0.4.2.

### 1.5. Deploy to SuiteX-Search ⏳ CHECKS RUNNING (PR #1850)

Agent was being deployed to NREC — wrong product. BryteHub registry form only shows SuiteX-Search agents.

**PR #1850**: https://github.com/UKGEPIC/ds-terraform-agents-pipeline/pull/1850
- Branch: `UpdateProPeopleApplicationAgentTo0.4.2` → `main`
- Copies ProPeopleApplicationAgent.json to all 4 SuiteX-Search envs
- Also: pub command updated to use SuiteX-Search paths going forward

- ExitAgentTool ✅ added to enigma.json (v0.4.3, ClientTool same as TalentPool)
- Default product ✅ changed to SuiteX-Search in lib/ds/config.rb
- rake bad ✅ deployed v0.4.3 (shows in /manage-agent but NOT /registry-form yet — needs pipeline)
- Branch updated to 4.1.246 after merging main conflict
- Required signatures may block merge — same issue as NER PR, may need --admin or manual merge

**After merge**: wait for agents pipeline CI to run, then /registry-form should find the agent.

### 2. Metadata PR ✅ MERGED

**PR #1192**: https://github.com/UKGEPIC/ds-terraform-ner-pipeline/pull/1192
- Branch: `enigma-metadata` → `develop`
- Version bump: 4.66.0 → 4.66.1 (merged develop, resolved conflicts)
- Entry added to dev, staging, preprod (removed psr — agent not deployed there, provisioning test was 404ing)
- All builds pass. Checkmarx security scan pending (blocks merge via branch protection).
- DEV PRs (feature → develop) don't need CODEOWNER approval — can self-merge once checks pass.

### 3. NER Training Pipeline ⏳

Auto-triggers after PR merge. Monitor: https://ukg.grafana.net/goto/HFT1DsyHg?orgId=1

### 4. Register Intent ✅ DONE

**PR #1446**: https://github.com/UKGEPIC/suitex-search-intent-registry/pull/1446
- Merged in suitex-search-intent-registry
- Intent Registry entry created in BryteHub with:
  - `type: "AGENT"`
  - `steps` array with `create-agent-session` and `send-agent-message` actions

### 5. Feature Flag ⏳ IN PROGRESS

**BryteHub `/feature-flag`** — submitted, auto-created PRs.

Flag key: `intent.agent.pro-people-application-agent`

**Auto-generated PRs**:
- **PR #1447**: https://github.com/UKGEPIC/suitex-search-intent-registry/pull/1447 (feature flag registry) ✅ MERGED
- **PR #2937**: https://github.com/UKGEPIC/launchdarkly-featuretoggles/pull/2937 ⏳ posted in #help-launchdarkly, waiting for review

**Jira**: PS-794515 (auto-created by BryteHub)

### Why this matters

The REC demo is blocked on this pipeline. The chat widget dispatches to the BFF, BFF looks up the intent in the Intent Registry, gets 404/500 because the agent isn't registered there yet. No shortcut — BFF always goes through Intent Registry.

## How to Create Metadata PRs

Create via GitHub API (not BryteHub button). Target `develop`. Bump version in setup.py, terraform-metadata.yml, version.txt. Add entry to `src/agents/us-east4/dev/{dev,staging}/agents_metadata.json`. Use 4-space indentation. `activation` goes top-level, not inside `description`.

## Entry Format

```json
{
    "name": "ProPeopleApplicationAgent",
    "version": "0.4.2",
    "description": {
        "primary_purpose": "Apply for a job through a guided conversational wizard",
        "intent_display_name": "Apply for a job",
        "skills": [
            {"name": "Collect application fields", "description": "..."},
            {"name": "Redirect to application form", "description": "..."}
        ],
        "user_scope": "All Employees",
        "people_scope": "Individuals",
        "time_scope": "Present",
        "action_type": "Creation, Navigation",
        "related_terms": ["apply", "job application", "quick apply", "candidate", "position", "opportunity", "submit", "career", "hiring"],
        "boundary_note": "..."
    },
    "team": "ProPeople",
    "contact_email": "maykel.suarez@ukg.com",
    "tenant-id": "00000000-0000-0000-0000-000000000000",
    "product-id": "SuiteX-Search",
    "active": true,
    "use_agent_examples": true,
    "use_tool_examples": null,
    "activation": {
        "capability_code": "Job Genius",
        "type": "Agent",
        "status": "DEV",
        "paid": "FREE",
        "product": [],
        "roles": ["EMPRL"],
        "platform": ["web"],
        "language": ["en"],
        "domain": "Talent Acquisition",
        "flag_key": "intent.agent.pro-people-application-agent"
    }
}
```

## Repos

| Repo | Branch | Purpose |
|------|--------|---------|
| ds-terraform-ner-pipeline | develop | Intent training metadata |
| suitex-search-intent-registry | develop | Intent registry |
