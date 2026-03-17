# Bryte Agent — Registration Runbook

Source of truth: Confluence "Bryte Agent Creation and Path to Production" (page 1023447142)

## Prerequisites

- Agent created in BryteHub /manage-agent
- Minimum 15-20 training examples in agent config
- ExitAgentTool added as ClientTool (required by registry-form)
- Default product set to `SuiteX-Search` in lib/ds/config.rb

## Step 1 — Deploy agent via agents pipeline

**Repo:** ds-terraform-agents-pipeline → `main`

1. Add agent JSON to `resources/dev/us-east4/dev-dev/SuiteX-Search/agents/{AgentName}.json`
   - dev-dev ONLY (match TalentPool PR #1532 pattern)
   - Version must match enigma.json
2. Bump `terraform-metadata.yml` and `version.txt`
3. PR title: `Adding a new feature for BryteHub-{AgentName}`
4. Needs CODEOWNER approval — post in #ai-frameworks-prs (no blocker language, just polite ask)
5. After merge: wait for pipeline to deploy. Agent will appear in BryteHub /registry-form

**Reference PR:** #1532 (ProPeopleAITalentPoolAgent)

## Step 2 — Test in BryteHub /chat

Verify the agent responds correctly before proceeding.

## Step 3 — NER metadata (intent training)

**Repo:** ds-terraform-ner-pipeline → `develop`

1. Add entry to `src/agents/us-east4/dev/{dev,staging}/agents_metadata.json`
   - Include `activation` top-level (not inside `description`)
   - Use 4-space indentation
   - tenant-id: `00000000-0000-0000-0000-000000000000`
   - product-id: `SuiteX-Search`
2. Bump version in `setup.py`, `terraform-metadata.yml`, `version.txt`
3. PR: feature → develop (DEV PRs can self-merge once checks pass)
4. After merge: NER training pipeline auto-triggers
5. Track: https://ukg.grafana.net/goto/HFT1DsyHg?orgId=1
6. Validate: NER score endpoint should return `agent_{name}_{tenant-id}_{product-id}`

**Do NOT add psr env** — agent not deployed there, will 404.

## Step 4 — Register intent in BryteHub /registry-form

Go to https://brytehub.suitex-search-dev.dlas1.ucloud.int/registry-form

- Search for agent by name — only appears after Step 1 pipeline completes
- Required fields:
  - type: AGENT
  - steps: create-agent-session + send-agent-message
  - customContext: any hardcoded context the agent tools need (e.g. rec.base_uri)
- BryteHub /registry-form auto-creates a PR in suitex-search-intent-registry — post in #ai-frameworks-prs for review

## Step 5 — Enable feature flag

Go to https://brytehub.suitex-search-dev.dlas1.ucloud.int/feature-flag

- Select the agent, click "Create Jira Ticket"
- This auto-creates 2 PRs:
  - suitex-search-intent-registry (flag registry) → post in #ai-frameworks-prs
  - launchdarkly-featuretoggles (LD flag) → post in #help-launchdarkly
- Both need review before the flag is live
- Key: `intent.agent.{kebab-case-agent-name}`

## Gotchas

- `rake bad` deploys to /manage-agent but NOT /registry-form — needs agents pipeline
- SDK `store` is local-only — never reaches BFF or agent. Context must come via intent registry `customContext`
- BFF always routes through Intent Registry — no bypass possible
- agents-pipeline targets `main`, requires CODEOWNER approval
- ner-pipeline targets `develop`, self-merge OK for dev
- Version conflicts: if CI fails "versions not bumped", merge develop/main first then bump patch
- Do NOT add dev-preprod to agents pipeline — dev-dev only for initial registration
- Correct Slack channels: agents pipeline + intent registry PRs → #ai-frameworks-prs; LD flag PR → #help-launchdarkly
- BryteHub /registry-form auto-creates a PR (not immediate) — need review
- BryteHub /feature-flag auto-creates 2 PRs and a Jira ticket — need review on both
