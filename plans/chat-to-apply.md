# Chat to Apply

## What This Is
Conversational interface for job applications — candidates apply to jobs through chat instead of traditional forms.

## Current Application Architecture

### Endpoints
| Flow | Endpoint | Controller | DTO |
|------|----------|------------|-----|
| Standard Apply | `POST /OpportunityApply/SubmitApplication` | `OpportunityApplyController` (line 306) | `ApplicationDto` |
| Quick Apply | `POST /QuickApply/ApplyOpportunityWithQuickApply` | `QuickApplyController` (line 426) | `QuickApplyDto` |
| External API | `POST /api/v2/applications` | `ApplicationV2Controller` (line 343) | `PostApplicationV2Dto` |

### Quick Apply vs Standard Apply
| | Quick Apply | Standard Apply |
|--|-------------|----------------|
| Auth | Anonymous | Logged in |
| Required | Name, Phone | Full profile |
| Resume | Optional upload | Parse + upload |
| Account | Auto-created | Existing |
| Captcha | Yes (Turnstile) | No |
| Duplicate check | `ValidateDuplicatedForQuickApply()` | Standard validation |

### Application Submission Flow
```
User → Form → Controller → ApplicationDtoMapper → Application domain model
  → IApplicationDomainService.SubmitApplication()
  → Generate assessments (if configured)
  → Redirect to ApplicationSubmitted page
```

### What Gets Collected
1. **Contact info** — name, phone, email
2. **Resume** — upload via `DocumentsController`, parsed by `IResumeParsingServiceClient`
3. **Screening questions** — `SubmitApplicationQuestionResponseDto` (text, numeric, multiple choice, date)
4. **Country questions** — EEO (USA), OFCCP (USA federal contractors), Canadian Diversity
5. **Consents** — candidate consent, text messaging, candidate match, copy applicants
6. **AI summary** — optional, via `UkgApplicantSummarizerClient` (already uses conversational AI pattern)

### Existing AI Integration
There's already an AI summarizer at `POST /OpportunityApply/GenerateApplicationSummary` using `UkgApplicantSummarizerClient`. It talks to a Data Science Gateway agent with conversation tracking (`InteractionId`). This is the closest existing pattern to what Chat to Apply would do.

## Quick Apply

Anonymous candidates, no account needed. Minimal fields.

**Endpoint**: `POST /QuickApply/ApplyOpportunityWithQuickApply`
**Controller**: `QuickApplyController.cs` (line 426)
**DTO**: `QuickApplyDto` (extends `RegisterCandidateDto`, wraps `ApplicationDto`)

**What gets collected**:
- First name, last name, phone (required)
- Email (optional)
- Captcha (Turnstile)
- Consents (candidate consent, text messaging)
- Screening questions (if configured on opp)
- Country questions (EEO/OFCCP/Canadian Diversity)
- Resume (optional file upload)

**Person creation**:
- Looks up by name + phone → if no match, creates new person
- If email provided → `RegisterDomainService.RegisterPerson()`
- If no email → `QuickApplyDomainService.SavePersonWithQuickApply()`
- Duplicate check via `ValidateDuplicatedForQuickApply()`

## Standard Apply

Authenticated candidates with existing accounts. Full profile.

**Endpoint**: `POST /OpportunityApply/SubmitApplication`
**Controller**: `OpportunityApplyController.cs` (line 306)
**DTO**: `ApplicationDto`

**What gets collected**:
- Contact information (from profile)
- Work experience
- Education
- Skills
- Behaviors
- Screening questions (text, numeric, multiple choice, date)
- Country questions (EEO/OFCCP/Canadian Diversity)
- Consents (candidate, text messaging, candidate match, copy applicants)
- Resume (upload + parsing via `IResumeParsingServiceClient`)
- AI-generated application summary (optional, via `UkgApplicantSummarizerClient`)

**Registration challenge**: Requires existing account + login. For chat, this means either reusing Quick Apply person creation or hitting UKG AuthN + OppAuthN.

## Registration Patterns (Precedent)

Both Quick Apply and Indeed Apply already solve inline person creation — no formal registration required.

| | Quick Apply | Indeed Apply |
|--|-------------|-------------|
| Identity key | Name + Phone | Email |
| Lookup | `GetAllPersonByNameAndPhoneNumber()` | `GetByAccountUsername(email)` (legacy) / `IIndeedApplyCandidateService.Resolve()` (new) |
| Multiple matches | Rejects — tells user to log in | Feature-flagged duplicate resolution |
| No match | Creates person inline | Creates person from Indeed applicant data |
| Registration call | `RegisterDomainService.RegisterPerson()` (if email) or `QuickApplyDomainService.SavePersonWithQuickApply()` (no email) | `RegisterDomainService.RegisterPerson()` always (email required) |
| Identity registration | Default yes | Conditional based on validation |
| Duplicate app check | Explicit `ValidateDuplicatedForQuickApply()` | `allowDuplicateApplications: false` at domain level |
| Consent | Candidate consent + SMS consent (separate) | 3rd-party consent processor (Indeed-specific) |

**Takeaway**: Standard Apply's "registration challenge" for chat is already solved. The pattern exists — create the person inline during submission, same as Quick Apply and Indeed do. No need to force candidates through a separate registration flow.

## Wizard Pattern (POC Architecture)

The agent is dumb. The wizards are smart.

### How it works
```
Agent                        Wizard Endpoint
  │                                │
  ├── POST {} (empty payload) ──→  │
  │                                ├── validate → "missing: firstName"
  │  ←── 400 {missing: firstName}──┤
  │                                │
  ├── ask user "What's your first name?"
  ├── user answers "John"          │
  │                                │
  ├── POST {firstName: "John"} ──→ │
  │                                ├── validate → "missing: phone"
  │  ←── 400 {missing: phone} ────┤
  │                                │
  ├── ask user "What's your phone number?"
  ├── ...repeat until 200          │
  │                                │
  ├── POST {complete payload} ──→  │
  │                                ├── validate → OK
  │  ←── 200 success ─────────────┤
  └── "You're all set!"           │
```

### Agent loop (pseudocode)
```
payload = {}
for each wizard in [registration_wizard, quick_apply_wizard]:
    while True:
        response = POST(wizard.url, payload)
        if response.status == 200:
            break
        missing = response.body.missing
        answer = ask_user(missing.question)
        payload[missing.field] = answer
```

### Key properties
- **Agent knows nothing** about the application schema. No field lists, no validation rules, no ordering logic.
- **Wizards own all decisions.** What's required, what order to ask, what's valid — all in the wizard.
- **Self-updating.** New required field? Add it to wizard validation. Agent adapts automatically.
- **Multiple wizards, one conversation.** User sees questions. They don't know there's a registration wizard, then a quick apply wizard. It's seamless.
- **Wizards are independent.** Each owns its own validation. Could be: registration, quick apply, standard apply, consent, etc.

### Design decisions & rationale

**Why one question at a time (not batched)?**
- The agent will run on a cheap/small model (not Opus). Dumber models reliably handle one question → one answer. Give them 5 fields to juggle and they drop things or combine them wrong.
- From the user's perspective, one question at a time feels like a conversation, not a form. The business already signed off on this UX.
- Designing for the weakest link (the LLM) by constraining its job to the absolute minimum.

**Why not a "smart agent" that reads the schema?**
- The team explored this — fetching opportunity config, parsing out required questions, figuring out answer types. It's the application team's domain knowledge baked into years of code. An agent shouldn't rediscover that.
- Makes the agent coupled to the domain. Any schema change breaks the agent's understanding.
- The wizard approach moves all that intelligence into code we control (the wizard), not prompts we hope work.

**Round-trip performance concern?**
- The wizard is pure validation logic — milliseconds per call.
- The bottleneck is the human typing, not the API.
- Agent-to-wizard calls are equivalent to tool calls, which agents already do routinely.
- Faster than sending a fat prompt to an LLM asking it to figure out the next question.

**The wizard is NOT just wrapping existing validation.**
- Current validation returns ModelState errors (multiple, field-name keyed, not human-readable).
- The wizard needs to: return one thing at a time, phrase it as a human question, and sequence fields in a logical order.
- That's new code — but it's deterministic code, not LLM prompt engineering. Easier to test, debug, and maintain.

### Candidate wizards
| Wizard | Purpose | Based on |
|--------|---------|----------|
| Registration | Create person / identity | `RegisterDomainService` validation |
| Quick Apply | Submit quick application | `QuickApplyController` validation |
| Standard Apply | Submit full application | `OpportunityApplyController` validation |

## Jira AC → Wizard Mapping (PS-726158)

| # | AC | Where it lives | Notes |
|---|-----|----------------|-------|
| 1 | Quick Apply integration effort | Quick Apply wizard | Wizard embeds QA validation, person creation, duplicate check |
| 3 | Standard Apply integration effort | Standard Apply wizard | Wizard embeds SA validation, requires authenticated session |
| 4 | Fit into existing AIVA chat | Agent orchestration | CTA agent lives alongside AIVA in same chat. Not a wizard concern |
| 5 | Multi-agent handoff (AIVA → CTA) | Agent orchestration | AIVA says "want to apply?", hands off to CTA agent. Above the wizard layer |
| 6 | Multi-language support | Wizard concern | Wizard returns questions in candidate's preferred language |
| 7 | Natural conversation flows for contact info | NOT a concern | Agent (LLM) naturally phrases questions. Wizard just returns field name + question text |
| 8 | Screener questions in chat | Apply wizard | Wizard knows which screener questions are configured, returns them one at a time with type (multiple choice, range, text) |
| 9 | Country questions in chat | Apply wizard | Wizard returns EEO/OFCCP/Canadian Diversity questions based on opportunity's legal entity |
| 10 | Registration info collection | Registration wizard | Wizard collects username, password, name — validates against registration settings |
| 11 | Identity system integration (UKGAuthN/OppAuthN) | Registration wizard internals | Plumbing inside the wizard. Agent never sees it |
| 12 | Resume upload in chat | Apply wizard + agent | Agent handles file receipt, wizard validates it was attached |

**Key takeaway**: Items 4 and 5 (multi-agent) are the only things above the wizard pattern. Everything else is either a wizard's internal concern or trivially handled by the agent being an LLM.

## Multi-Agent with AIVA
- AIVA provides job recommendations
- Chat to Apply agent handles the application
- Handoff pattern between agents

## Key Files to Know
- `Controllers/OpportunityApplyController.cs` — standard apply logic
- `Controllers/QuickApplyController.cs` — quick apply logic + person creation
- `Controllers/DocumentsController.cs` — resume upload
- `Domain/Services/DataScience/UkgApplicantSummarizerClient.cs` — existing AI agent pattern
- `Recruitment.Application.Services/Dto/CoreModule/ApplicationDto.cs` — standard apply DTO
- `Recruitment.Application.Services/Dto/CoreModule/QuickApplyDto.cs` — quick apply DTO
- `Views/OpportunityApply/Index.cshtml` — standard apply form (reference for what fields exist)
- `Views/QuickApply/Index.cshtml` — quick apply form
