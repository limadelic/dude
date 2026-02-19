# Liz Plan

## What Liz does
Reads Jira story + Diego's Confluence notes + codebase → writes AC table in Jira.
No browser. No navigation. Jira + Confluence + codebase only.

## Current state
- `liz.md` at `.claude/agents/liz.md` — iterated to 95% eval (80/84 ACs)
- `eval.md` at `.claude/agents/eval.md` — scorer agent
- `dataset.json` at `.claude/skills/lizas/evals/dataset.json` — 5 Bulk Apply stories
- MCPs: `.mcp.json` is empty — need Jira + Confluence

## Eval results (final)
79% → 83% → 88% → 93% → 95% over 4 iterations.

| Story | Score | % |
|---|---|---|
| Choose Opp (≤20) | 20/20 | 100% |
| Choose Opp (>20) | 18/19 | 95% |
| Red Banner Retry | 18/19 | 95% |
| Completion Banners | 14/15 | 93% |
| Notify Validations | 10/11 | 91% |

Remaining 4 misses need context from Confluence (not in sparse Jira descriptions).

## Eval is artificially harder than production
- Eval feeds story CONTENT only — no Confluence, no epic links
- In production, Liz reads Diego's Confluence notes with full detail
- The 4 remaining misses (pool-page nav, retry nav, banner replacement, subtext copy) would likely be covered with Confluence context

## New intel from Diego
- Diego writes freeform notes in Confluence first (not formal specs)
- Jira stories link to Confluence/epic pages
- Liz should read Confluence before writing ACs

## Liz's tools
- Jira MCP (read/write stories, comments)
- Confluence MCP (read Diego's notes — follow links from Jira)
- Codebase search (existing tests, page objects, views, components)
- NO browser, NO Magellan, NO elkano

## Liz has two modes
- **Create** — ACs field is empty → write the table
- **Review** — ACs exist → check for gaps, suggest additions

## Key Jira knowledge
- Acceptance Criteria = `customfield_14400` (not in description)
- Story IDs: `PS-XXXXXX` format
- Bulk Apply PO: Diego La Hoz — writes thorough tables, good ground truth

## What's left

### 1. Configure MCPs
- [ ] Jira MCP
- [ ] Confluence MCP

### 2. Update liz.md workflow
- [ ] Add Confluence step: follow links from Jira, read Diego's notes
- [ ] This is the biggest improvement available

### 3. Live story test
- [ ] Pick a story Liz has never seen (not in dataset)
- [ ] Run with Jira + Confluence MCPs live
- [ ] Compare to Diego's actual ACs

### 4. Reconcile file structure
- [ ] liz.md lives at `.claude/agents/liz.md` now
- [ ] SKILL.md router still points to `.claude/skills/lizas/liz.md` (old path)
- [ ] Decide: keep agents dir or move back to skills?

## Parking lot
- SDD (spec-driven development) — Liz already does the useful part
- Cross that bridge if org mandates it
- Eval update for Confluence context — accept eval is a floor for now
