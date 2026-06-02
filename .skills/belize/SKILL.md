---
name: belize
description: Lisa writes scenarios, Eric reviews adversarially, Dude arbitrates
---

# Belize

- Read local belize for project-specific DSL and rules
- This skill defines the process, the local defines the language

## The Cast

| Name | subagent_type | Model  |
|------|---------------|--------|
| lisa | lisa          | sonnet |

- Lisa is the ONLY team member
- Eric is a subagent, spawned fresh for each review

## The Loop

### Write Feature

- Read the existing DSL first
- Feed lisa the DSL and input scenarios
- Lisa writes ALL scenarios into one `.feature` file
- Maximize DSL reuse
- No new step definition files unless necessary

### Review

- Use subagent eric to review the feature file
- Use team agent lisa to adjust what you consider valid
- Repeat while valid concerns arise

### Human Review

- Present `.feature` to user
- User approves or back to review loop

## Setup

- `/sup` the team with the cast above
- Confirm lisa replies

## Input

- A 3-amigos plan, a feature idea, whatever you have
- You frame it for lisa

## Exit

- All scenarios green
- Called from `/3-amigos`, scenarios turn the plan into tests
- Hand off to `/katmandu` when a scenario is red
