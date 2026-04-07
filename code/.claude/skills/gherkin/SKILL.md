---
name: gherkin
description: The Gherkin loop — Lisa writes scenarios, Eric reviews, Dude approves
---

# Gherkin

## Setup

- Use `/sup` to start the team with the cast below
- Confirm lisa replies before proceeding

## The Cast

Spawn with EXACTLY this name and subagent type:

| Name | subagent_type | Model  | Role                                              |
|------|---------------|--------|----------------------------------------------------|
| lisa | lisa          | sonnet | writes scenarios and step definitions, keeps context |

Lisa is the ONLY team member. She persists across all scenarios in the feature — context makes her better each round.

**Eric is NOT in the team.** Spawn him as a plain `Agent` (subagent_type: `eric`, model: `sonnet`, no `team_name`) for each review. Fresh eyes, dies after returning feedback.

## Tasks

On start, create one task per scenario from the input (all `pending`). Mark each `in_progress` when you start it, `completed` when green. If you enter `/katmandu`, create a sub-task for it — keeps you anchored through the nested loops.

## The Loop

One scenario at a time. Repeat until the feature is done.

### 1. Scenario (lisa)

Pick the next scenario from the input (plan, list, or conversation) and tell lisa to write it. Scenario only — no step definitions yet. Lisa owns the format and file structure.

### 2. Review (eric)

Spawn eric to review the scenario for domain language and glossary.

### 3. Decide (dude)

Review lisa's scenario and eric's feedback. If eric flagged issues, send lisa back. Glossary flags → add or reject. Otherwise, flow.

### 4. Step Definitions (lisa)

Tell lisa to write step definitions for the approved scenario. Lisa owns the `@wip` and `pending` conventions — just tell her which scenario.

### 5. Review Steps (eric)

Spawn eric to review step defs for domain alignment. If he flags issues, send lisa back. Otherwise flow straight to verify.

### 6. Verify (lisa)

Tell lisa to run the `@wip` scenario. Green → remove tag, `/bob` commits, go to 7. Red → run `/katmandu` with the failing scenario as the behavior description, then re-verify.


## Input

The prompt tells you what to gherkin on — a 3-amigos plan, a feature idea, whatever. No special format required.

## Exit

All scenarios green, all `@wip` tags removed. Glossary updates ship with the feature.
