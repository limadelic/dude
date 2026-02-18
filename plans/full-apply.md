# Apply with Resume — POC Plan

## Concept
Resume-first application. Candidate drops a resume, system parses it, agent fills in what it can and asks for the rest. Claude Code acts as the agent for the POC.

## Branch
`apply-with-resume` off `main`

## The Flow (Agent POC)

```
1. POST to wizard with opportunityId only → wizard says "missing: resume"
2. I ask user for resume file
3. I upload file to existing ResumeParsingForQuickApply endpoint
   → system stores file, parses it, returns fileId + parsed contact info
4. I POST to wizard again with fileId + parsed contact fields (firstName, lastName, phone, email)
   → wizard checks what's still missing after resume data
5. Wizard says "missing: consent" (or whatever the resume didn't cover)
6. I ask user, add answer to payload, POST again
7. Repeat until 200 → application submitted
```

### Three concerns, three actors
- **Existing system** (`ResumeParsingForQuickApply`): uploads file, parses resume, returns fileId + parsed data
- **Agent** (me): relays between user and wizard, calls the upload endpoint, feeds parsed data to wizard
- **Wizard** (`ResumeApplyWizardController`): receives payload, says what's missing, at submission attaches resume via fileId (same as QuickApply: look up file by ID, wrap as PersonDocumentDto, attach to ApplicationDto.Documents)

## New Controller: ResumeApplyWizardController

NOT the QuickApplyWizardController. Different feature, different name, different flow.

Based on the wizard pattern from `origin/quick-apply-wizard` branch but adapted for resume-first:
- Receives a `fileId` from a previously parsed resume instead of asking for name/phone/email one by one
- Pulls contact info from the parsed resume data (`ResumeParsingCandidateDetailDto`)
- Only asks for what the parser didn't cover (consents, screening questions, country questions)
- Falls back to asking for contact fields only if the parser missed them

### Wizard Request Shape
```csharp
public class ResumeApplyWizardRequest
{
    public Guid? OpportunityId { get; set; }
    public Guid? FileId { get; set; }           // From ResumeParsingForQuickApply response
    // Overrides (if parser missed or user corrects)
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Phone { get; set; }
    public string Email { get; set; }
    // Consent + questions (same as QuickApplyWizard)
    public bool? CandidateConsent { get; set; }
    public bool? ResumeAsked { get; set; }       // Always true (resume already uploaded)
    public Dictionary<string, string> CountryQuestionAnswers { get; set; }
    public Dictionary<string, string> ScreeningQuestionAnswers { get; set; }
}
```

### Wizard Flow
```
1. Require opportunityId → look up opp
2. Require fileId → if missing, return Missing("resume", "Please upload your resume", "file")
3. Check firstName, lastName, phone, email (agent passed these from parsed resume)
   → if any missing, ask for them (parser didn't find them)
4. Ask for consent
5. Ask for country questions (if opp requires)
6. Ask for screening questions (if opp has them)
7. Submit: create person + attach resume via fileId (same as QuickApply: wrap as PersonDocumentDto) + submit application
```

### Key Difference from QuickApplyWizard
- QuickApplyWizard: asks for every field one by one, resume is optional at the end
- ResumeApplyWizard: resume is FIRST, contact info comes FROM the resume, only gaps get asked

## Existing Endpoints Used

| Step | Endpoint | Auth | Notes |
|------|----------|------|-------|
| Resume upload + parse | `POST /{tenant}/Documents/ResumeParsingForQuickApply` | Anonymous | Multipart form, returns parsed `ResumeParsingCandidateDetailDto` |
| Submit (wizard) | `POST /{tenant}/JobBoard/{jobBoardId}/ResumeApplyWizard` | Anonymous | New endpoint, JSON body |

## What ResumeParsingForQuickApply Returns

```json
{
  "success": true,
  "data": {
    "fileId": "guid",
    "contactInformation": {
      "personName": { "givenName": "...", "familyName": "..." },
      "email": "...",
      "primaryPhoneNumber": "...",
      "address": { "city": "...", "state": "...", "postalCode": "...", "country": "..." }
    },
    "workExperiences": [...],
    "educations": [...],
    "skills": [...]
  }
}
```

## Mapping: Parsed Resume → Person Creation

| Person Field | Source | Fallback |
|-------------|--------|----------|
| `FirstName` | `parsed.contactInformation.personName.givenName` | Ask user |
| `FamilyName` | `parsed.contactInformation.personName.familyName` | Ask user |
| `PhoneNumber` | `parsed.contactInformation.primaryPhoneNumber` | Ask user |
| `Email` | `parsed.contactInformation.email` | Ask user |
| `fileId` | `parsed.fileId` | — |
| `HasAcceptedConsentMessage` | — | Ask user |
| `CountryQuestions` | — | Ask user (if opp requires) |
| `ScreeningQuestionAnswers` | — | Ask user (if opp has them) |

## Dependencies / Injections for ResumeApplyWizardController

Same as QuickApplyWizardController:
- `IOpportunityAppService` — opp lookup
- `IQuickApplyDomainService` — person save (no email)
- `IApplicationDomainService` — submit + duplicate check
- `IPersonRepository` — person lookup by name+phone
- `IOpportunityRepository` — opp domain model
- `IJobBoardDomainService` — job board context
- `ITenantRepository` — tenant settings (assessment autolaunch)
- `ApplicationDtoMapper` — DTO → Application domain
- `QuickApplyDtoMapper` — DTO → Person domain
- `IFileRepository` — look up uploaded file by fileId for resume attachment

## Resume Attachment at Submission

Same pattern as QuickApply. The wizard receives `fileId` from the agent. At submission:
1. Look up file by `fileId` via `IFileRepository`
2. Wrap as `PersonDocumentDto { DocumentType = "Resume", FileId = fileId, CreatorId = person.Id }`
3. Attach to `ApplicationDto.Documents`

Agent is responsible for:
1. Calling `ResumeParsingForQuickApply` (existing endpoint, multipart form upload)
2. Extracting `fileId` + contact fields from the response
3. Passing both to the wizard in subsequent POSTs

## POC: Claude Code as Agent

For the POC, I (Claude Code) act as the agent:
- I call `ResumeParsingForQuickApply` via curl with the file from disk
- I extract parsed data from the response
- I call the wizard endpoint via curl, feeding in parsed data
- I relay wizard's "missing" responses to the user via conversation
- I add user's answers to the payload and POST again
- Repeat until 200

## Implementation Tasks

- [ ] Create `ResumeApplyWizardController.cs` in `Controllers/InternalApi/`
- [ ] Wire up: opp lookup → require fileId → check contact fields → consent → country → screening → submit with resume attachment
- [ ] Test with curl against local dev
- [ ] Test full flow: upload resume → wizard loop → submitted application

## Status: WORKING END-TO-END (Feb 12)

### Verified curl test
```bash
BASE="https://localhost:5001/mordor/JobBoard/b316e881-cab2-999a-b0a0-838bfaaff491/ResumeApplyWizard"
OPP="20badf49-0d7e-c88c-a5b6-070e96f79308"

# Step 1: Just opportunityId → asks for resume
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'"}'
# → {"field":"resume","question":"Please upload your resume.","type":"file"}

# Step 2: With resume data (simulating parsed result) → asks for consent
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'","fileId":"00000000-0000-0000-0000-000000000001","firstName":"John","lastName":"Doe","phone":"5551234567","email":"john.doe@example.com"}'
# → {"field":"candidateConsent","question":"Do you consent to...","type":"boolean"}

# Step 3: With consent → submitted
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'","fileId":"00000000-0000-0000-0000-000000000001","firstName":"John","lastName":"Doe","phone":"5551234567","email":"john.doe@example.com","candidateConsent":true}'
# → {"status":"submitted","candidateId":"bd0a2e2c-2788-4f41-af4a-96044fc1e275"}
```

## POC Constraint: Sovren Not Available Locally

`ResumeParsingForQuickApply` calls Sovren (external parser) — not reachable from local dev. For the POC:
- Agent (me) reads the resume file directly and extracts contact info manually
- Passes extracted fields + no fileId to the wizard
- Proves the wizard loop works with resume-derived data
- File attachment is same pattern as QuickApply (already proven) — not blocked by this

## Local Environment (from quick-apply-wizard plan)
- Tenant: `mordor`
- Finance Manager opp: `20badf49-0d7e-c88c-a5b6-070e96f79308`
- Job board: `b316e881-cab2-999a-b0a0-838bfaaff491`
- EscapeCaptcha toggle: should be active
- Harvey Dent (recruiter): `77777941-1ab9-b0bb-247b-e302b1852410`
