# Enigma (ProPeopleApplicationAgent)

## What It Is

- Dumb agent — relays between user and wizard endpoint
- Wizard pattern: POST payload → wizard returns "missing: X" with question → agent asks user → adds answer → POST again → repeat until complete
- Wizard is a field collector, NOT an application submitter — it never touches the DB
- Final 200 means "all fields collected" and returns the complete field set: `{status: "complete", fields: {firstName: "John", ...}}`
- Agent then signals redirect with the collected fields → chat widget redirects to QuickApply page with query params pre-filled → user reviews and submits
- Wizard owns all brains: field ordering, validation, what's required
- Agent owns nothing about the application schema — self-updating when wizard changes
- 1 RESTTool pointing at wizard endpoint (path is context-driven for test/prod flexibility)
- Instructions: "POST, relay the question, collect the answer, POST again until complete, then call RedirectToQuickApply ClientTool"
- Redirect is a **ClientTool** (`RedirectToQuickApply`) — agent calls it with collected fields as args
- ClientTool fields are typed (string, int, float, date)
- Country/configurable questions — wizard returns them like any other question, answers are just strings.
- Client-side handling (SSE, BFF, widget redirect) documented in `rec-enigma.md`

## Wizard (not deployed yet)

- QuickApplyWizard — future controller wrapping QuickApply logic in conversational loop
- Wizard doesn't exist on any environment yet
- Real QuickApply logic lives in `QuickApplyController.cs` (MVC, form-post, not REST)

## The Frankenstein (POC Architecture)

Three environments stitched together:
1. **localhost** — REC app running locally with SDK chat UI (only exists locally)
2. **DS gateway** — real Enigma agent, deployed for real
3. **rec-preview** — where Enigma's tool calls land (not localhost, DS can't reach localhost)

The chat on localhost talks to the real Enigma on DS. Enigma's tool hits rec-preview.
Enigma doesn't know or care which parts are fake — it just talks to its tool endpoint.

## Deployment

- **Product**: `SuiteX-Search` (NOT NREC) — the bryte SDK chat only sees SuiteX agents
- Deploy: `DS_PRODUCT_ID=SuiteX-Search rake bad[enigma]`
- Test base sets `DS_PRODUCT_ID` to `SuiteX-Search` automatically
- Use minor version bumps (0.4.1, 0.4.2, etc.)

## Gotchas Learned

- **`safe: false`** on RESTTool = tool waits for user confirmation, never executes in tests. Must be `safe: true`.
- **Guillotine stubs don't guarantee FIFO** — multiple `once: true` stubs on the same URL come back in arbitrary order. Stub ONE question at a time between messages.
- **Guillotine can only stub existing routes** — controller must be registered in the app. Can't stub `QuickApplyWizard` (doesn't exist). Stub `POST applications` instead.
- **`X-TestApiBypass: true`** header needed on the tool for stub interception to work on POST endpoints.

## POC Testing Strategy

- Stub `POST /{tenant}/api/applications` (exists on `ApplicationV2Controller`) to return wizard-like responses
- Stub URL pattern: `"applications"` matches the route
- Stub ONE question at a time, send message, stub next question, send next message
- `Gui.delete_all` in setup to clean stubs between tests

## Test: Chat to Apply (working)

Single test walks the full conversation:
1. Stub firstName question → send "I want to apply" → assert asks first name
2. Stub lastName question → send "John" → assert asks last name
3. Stub email question → send "Doe" → assert asks email
4. Stub consent question → send "john@test.com" → assert asks consent
5. Stub complete response → send "Yes" → assert `RedirectToQuickApply` ClientTool fires with collected fields

The test validates: agent relays each question, collects answers, and fires the ClientTool redirect at the end with all fields as args.

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

## Stories

1. Agent config + tool definition — JSON config, 1 RESTTool (context-driven path), RedirectToQuickApply ClientTool, instructions
2. Test suite — functional tests for wizard relay loop using stubs, basic guardrails
3. UI — see `rec-enigma.md` (REC repo work)
