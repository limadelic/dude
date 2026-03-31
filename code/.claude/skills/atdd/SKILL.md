---
name: atdd
description: ATDD loop — lisa writes features, katmandu makes them pass
---

# atdd

Lisa → Eric → Katmandu → Lisa verification loop.

## 1. Scenarios (lisa)

Delegate to `lisa` (model: "opus"): write scenarios, no step definitions yet.

## 2. Review (eric)

Delegate to `eric` (model: "opus"): review the scenarios for domain language.

## 3. Approve (dude)

YOU review. If good, proceed. If not, send lisa back.

## 4. Step Definitions (lisa)

Delegate to `lisa` (model: "opus"): write step definitions, tag `@wip`, use `pending` for kenny.

## 5. Review Steps (eric)

Delegate to `eric` (model: "opus"): review step defs for domain alignment.

## 6. Katmandu

Run /katmandu to make the steps pass.

## 7. Verify (lisa)

Delegate to `lisa` (model: "opus"): run `@wip` scenarios. Green → remove tag, commit. Red → back to 6.
