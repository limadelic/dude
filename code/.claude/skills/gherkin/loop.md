# The Loop

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

On start, create one task per scenario from the input (all `pending`). Mark each `in_progress` when you start it, `completed` when green.

## Steps

One scenario at a time. Repeat until the feature is done.

### 1. Write (lisa)

Pick the next scenario and tell lisa to write it — scenario, step definitions, and any support code needed. All step definitions use mocks and stubs. Lisa touches only feature and scenario code, never production code.

### 2. Review (eric)

Spawn eric to review the scenario and step definitions for domain language and glossary alignment.

### 3. Decide (dude)

Review lisa's work and eric's feedback. If eric flagged issues, send lisa back. Glossary flags → add or reject. Otherwise, flow.

### 4. Verify (lisa)

Tell lisa to run the `@wip` scenario. Green → remove tag, `/bob` commits. Red → send lisa back to fix until green.

## Input

The prompt tells you what to gherkin on — a feature idea, a list of scenarios, whatever. No special format required.

## Exit

All scenarios green, all `@wip` tags removed. Glossary updates ship with the feature.
