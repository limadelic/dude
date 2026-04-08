---
name: qa
description: Lisa writes features for existing code — no code changes allowed
---

# qa

Lisa covers existing behavior with Cucumber scenarios.

## 1. Scenarios (lisa)

Delegate to `lisa` subagent (model: "opus"):
- Write scenarios for existing behavior
- Focus on what the code ALREADY does
- Return the feature file for dude to review

## 2. Review (eric)

Delegate to `eric` subagent (model: "opus"):
- Pass lisa's scenarios for domain language review
- If eric raises real violations, send lisa back with feedback
- If eric is nitpicking, proceed

## 3. Approve (dude)

YOU review the scenarios:
- If scenarios capture existing behavior, proceed
- If not, send lisa back with feedback

## 4. Step Definitions (lisa)

Delegate to `lisa` subagent (model: "opus"):
- Write step definitions for the approved scenarios
- Step defs must work against existing code — NO scaffolding

## 5. Review Steps (eric)

Delegate to `eric` subagent (model: "opus"):
- Check step defs are tied to domain code — no bypasses, no mocks, no drift
- If violations, send lisa back
- If clean, commit feature + steps

## 6. Verify (lisa)

Delegate to `lisa` subagent (model: "opus"):
- Run the scenarios
- If green → commit, done
- If red → dude diagnoses: test wrong or code wrong?
  - Test wrong → send lisa back to step 4
  - Code wrong → run /katmandu to fix it
