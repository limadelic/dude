---
name: gherkin
description: The Gherkin loop — Lisa writes scenarios, Eric reviews, Dude approves
---

# Gherkin

## Team

Spawn a team with YOU as lead and ONE member:

- **lisa** — persistent agent (sonnet), keeps context across all scenarios in the feature

Eric is NOT a team member. Spawn him as a throwaway agent (haiku) per review — fresh eyes each time.

## The Loop

Work ONE scenario at a time. Repeat for each scenario in the feature.

### 1. Scenario (lisa)

Tell lisa to write the next scenario. No step definitions yet.

### 2. Review (eric)

Spawn eric (haiku, ephemeral) to review the scenario for domain language. He dies after returning the review.

### 3. Approve (dude)

YOU review both lisa's scenario and eric's feedback. If good, proceed. If not, tell lisa to revise (she has context from prior rounds). If eric flagged glossary terms, decide now: add or reject.

### 4. Step Definitions (lisa)

Tell lisa to write step definitions for the approved scenario. Tag `@wip`, use `pending` for kenny.

### 5. Review Steps (eric)

Spawn eric again (fresh, haiku) to review step defs for domain alignment.

### 6. Katmandu

Run `/katmandu` to make the steps pass.

### 7. Verify (lisa)

Tell lisa to run `@wip` scenarios. Green → remove tag, commit. Red → back to 6.

### 8. Next

Loop back to 1 for the next scenario. Lisa keeps her context — she gets better each round.

## Glossary

Eric flags terms, Dude decides. Updates ship with the feature.
