# Enigma (ProPeopleApplicationAgent)

## What It Is

- Dumb agent — relays between user and wizard endpoint
- Wizard pattern: POST payload → wizard returns "missing: X" with question → agent asks user → adds answer → POST again → repeat until 200
- Wizard owns all brains: field ordering, validation, what's required
- Agent owns nothing about the application schema — self-updating when wizard changes
- 1 RESTTool pointing at wizard endpoint
- Instructions: "POST, relay the question, collect the answer, POST again until submitted"

## Wizards (already built, POC complete)

- QuickApplyWizard — `POST /{tenant}/JobBoard/{jobBoardId}/QuickApplyWizard`
- ResumeApplyWizard — `POST /{tenant}/JobBoard/{jobBoardId}/ResumeApplyWizard`
- See plans: `quick-apply-wizard.md`, `apply-with-resume.md`

## Reference: Ruth Agent Structure

Ruth (ProPeopleCandidateSourcingAgent) — production agent baseline:
- Main config JSON + 6 alt configs for testing
- 8 tool definitions with Jinja2 response templates
- 5 MongoDB aggregation pipelines
- 55+ tests: functional (35), guardrails (20+), stress
- Test fixtures (17 data files), context.rb
- Deployment: Rakefile tasks (new, msg, bad, pub), shell scripts

## Enigma vs Ruth

- Much simpler: 1 tool, no templates, no aggregations, no complex instructions
- Still needs: config, tool def, tests, guardrails, fixtures, deployment wiring
- Same development process, less content

## Question Types (wizard returns these)

- Text — free text (name, email, phone)
- Boolean — yes/no (consent, SMS opt-in)
- Multiple choice — pick from list (screening, country questions)
- Numeric — number input (years of experience)
- File — resume upload

## UI — Existing Components (REC repo)

Chat UIs:
- **Bryte Chat** (shared) — `Containers/Recruiters/Bryte/Chat/` — messages, input, feedback, candidate cards
- **CandidateSourcing** (Ruth's wrapper) — `Containers/OpportunityApplicants/CandidateSourcing/` — Button → Modal → BryteChat + BryteContext (state, sendMessage, warmup, feedback)
- **AIVA ChatBot** (candidate, job board) — `Containers/JobBoard/AIVAChatBot.tsx` — floating drawer widget

Question renderers:
- `ScreeningQuestions.tsx` — MultipleChoice (radio), Text (textarea), Numeric (number input)
- `ApplicationQuestionsUSA.tsx` — EEO: dropdowns, radio, checkboxes, "decline to answer"

Design system: Ignite — UkgAiDrawer, UkgAiMessageBubble, UkgRadioGroup, UkgSelect, etc.

Pattern for Enigma UI: same as CandidateSourcing — thin wrapper + context + shared chat component
- Question renderers need to work inside chat bubbles instead of form accordions

## Stories

1. Agent config + tool definition — JSON config, 1 RESTTool for wizard endpoint, instructions
2. Test suite — functional tests for wizard relay loop, basic guardrails
3. UI — wire question renderers into chat flow (reuse ScreeningQuestions + EEO components in chat bubbles)
