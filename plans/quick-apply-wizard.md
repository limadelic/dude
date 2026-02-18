# Quick Apply Wizard — Chat to Apply POC

## What it is
A wizard endpoint that an AI agent calls repeatedly to apply on behalf of a candidate. The wizard returns one missing field at a time. Agent asks the candidate, adds the answer, POSTs again. When all data is collected, the wizard submits the application.

## Status: POC COMPLETE — DEMO READY (Feb 12)

## Route
`POST /{tenant}/JobBoard/{jobBoardId}/QuickApplyWizard`

## How it works
1. Agent POSTs with `opportunityId` → wizard asks for `firstName`
2. Agent adds `firstName`, POSTs again → wizard asks for `lastName`
3. ... repeat through phone, email, consent, countryQuestions, screeningQuestions, resume
4. When all fields present → wizard creates person, submits application, returns `{"status":"submitted","candidateId":"..."}`

## Controller
- File: `Controllers/InternalApi/QuickApplyWizardController.cs`
- Extends `BaseController` (tenant context) with `[JobBoardSpecific]` + `[AllowAnonymous]`
- Injects domain services directly: `IQuickApplyDomainService`, `IApplicationDomainService`, `IPersonRepository`, `IOpportunityRepository`, `ApplicationDtoMapper`, `QuickApplyDtoMapper`, `ITenantRepository`, `IJobBoardDomainService`
- Submission flow: `QuickApplyDtoMapper.ToPerson()` → check existing persons → `SavePersonWithQuickApply()` → `ApplicationDtoMapper.ToApplication()` → `ValidateDuplicatedForQuickApply()` → `SubmitApplication()`
- No captcha (API-to-API, not browser)

## Curl test
```bash
BASE="https://localhost:5001/mordor/JobBoard/b316e881-cab2-999a-b0a0-838bfaaff491/QuickApplyWizard"
OPP="20badf49-0d7e-c88c-a5b6-070e96f79308"
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'","firstName":"Mike","lastName":"Hero","phone":"1112221234","email":"mike.hero@test.com","candidateConsent":true,"resumeAsked":true}'
# → {"status":"submitted","candidateId":"a6b7950b-aac6-49cd-baf8-3f0d8955f7b7"}
```

## Verified
- Wizard question loop works (firstName → lastName → phone → email → consent → countryQuestions → screeningQuestions → resume → submitted)
- Person created in Mongo (IsQuickApplyCandidate=true)
- Application created in Mongo (linked to Finance Manager, Status=Applied)
- Visible in recruiter UI: logged in as Harvey Dent (TwoFace Dent), candidate detail page works
- Country questions persist to Mongo (tested USA: Gender, Ethnic Origin, Veteran, Disability — all with "Decline" answers)
- Country questions read dynamically from DB with real choices (no hardcoded options)
- Multiple candidates tested: Mike Hero, Jesus Jesus
- Applicants list doesn't show applicant (ES reindex needed — not wizard issue)

## Local environment setup
- Finance Manager opp GUID: `20badf49-0d7e-c88c-a5b6-070e96f79308` (set to OpportunityType=1)
- Job board GUID: `b316e881-cab2-999a-b0a0-838bfaaff491`
- QuickApply toggle: active in FeaturePreview collection
- EscapeCaptcha toggle: active in FeaturePreview + Tenant.Features
- Bypass login: `/{tenant}/Test/SetLoginCookie?personId={guid}`
- Harvey Dent GUID: `77777941-1ab9-b0bb-247b-e302b1852410`
- Test data class: `Recruitment.Persistence.Migrations/TenantMigrations/Test/RecruitmentAdministratorTestData.cs`

## System tests
- Location: `Product/Recruitment.SystemTests.NetCore/CandidateExperience/JobBoard/QuickApply/`
- QuickApplyTests.cs — 21 tests, full candidate flow
- Page objects: `Recruitment.Echo.Context.Rec14.NetCore/PageObjects/`
- Test login: `Rec14.Macros.Session.NavigateAndLogin(personId)` → `/{tenant}/Test/SetLoginCookie?personId={guid}`

## Key files
- `Controllers/InternalApi/QuickApplyWizardController.cs` — the wizard (NEW)
- `Controllers/QuickApplyController.cs` — existing quick apply (reference)
- `Views/QuickApply/Index.cshtml` — quick apply form view
- `Scripts/site/knockout-models/Opportunity/viewmodels/OpportunityDetailViewModel.ts` — showQuickApply() logic
- `Views/OpportunityDetail/_ApplyButtons.cshtml` — quick apply button (Knockout)

## How resume works in existing QuickApply
- Candidate uploads file via browser → stored server-side → returns a `fileId` (GUID)
- At submission, `QuickApplyController` line 536: looks up file by `fileId` via `fileRepository.GetFileInfo()`
- Wraps it into `PersonDocumentDto { FileName, FileId, CreatorId, DocumentType = "Resume" }`
- Attaches to `ApplicationDto.Documents`
- Resume is NOT a separate process — it's just a file ID linked at submission time
- `QuickApplyDto` has a `fileId` string property for this
- `IsResumeRequired` on the opportunity controls whether it's mandatory

## POC fixes applied (Feb 12)
- [x] Country/screening question answers now wired into `QuickApplyDto` and `ApplicationDto`
- [x] `MapCountryQuestions()` converts wizard dict keys → `ApplicationCountryQuestionDto` with proper `CountryQuestion.*` constants
- [x] `MapScreeningResponses()` converts wizard dict → `SubmitApplicationQuestionResponseDto` with correct `ResponseType`/`TextResponse`/`NumericResponse`
- [x] Added error details to submission failure responses
- [x] Verified country questions persist to Mongo (tested CAN: VisibleMinority="Chinese", IndigenousIdentity="Metis" → saved on Application.CountryQuestions)
- [x] Verified basic flow persists person + application (no country questions → empty arrays, correct)

## POC fixes applied (Feb 12, round 2)
- [x] Country questions now fully dynamic — reads from `CountryQuestion` collection by `CountryCode`, no hardcoded map
- [x] Choices come from `dbQ.Choices` (DB), not hardcoded arrays
- [x] `MapCountryQuestions` uses question name as key directly (e.g. `{"VisibleMinority": "Chinese"}`)
- [x] Existing `QuickApplyController` line 669-676 has same hardcoded map pattern — wizard is now cleaner than existing code

## Known notes
- Existing `QuickApplyController` uses `shouldValidateQuestion` dict + `ConfigurableCountryQuestions` toggle + `USFederalContractor` logic for filtering — wizard skips this for POC simplicity
- Country questions are embedded in Opportunity document — legal entity flag changes require updating both `LegalEntity` collection AND embedded `Opportunity.LegalEntity`
- Answer validation happens at domain level via `ApplicationCountryQuestionDtoMapper`
- ~~POC shortcut: wizard injects `ICountryQuestionRepository` directly~~ FIXED: now uses `ICountryQuestionDomainService.GetCountryQuestionsOfOpportunity(opportunity)` — same pattern as `AddApplicationsController` (line 587) and `OpportunityCountryQuestionsV2Controller` (line 85). Toggle checks + legal entity filtering handled by domain service.
- Story TODO: add `IApplicationCountryQuestionValidator` for answer validation
- Opportunity currently set to USA country code (switched from CAN for demo — USA questions have "Decline" options)

## Stories
1. Wizard endpoint with shared submission service, toggle check, unit tests, and system tests

## Out of scope (separate effort)
- Resume upload — different approach planned, not part of wizard stories
- Rate limiting — infrastructure concern, not a feature; endpoint is agent-to-API behind toggle

## Next steps
- [ ] Refactor submission logic to shared service (QuickApplyController + wizard both duplicate it)
- [ ] Fix ES reindex so applicants show in list

## Demo script (Feb 13)

### Pre-flight
1. Use `building-and-testing` skill to ensure site is running on port 5001 from the correct branch
2. Hit the wizard endpoint with curl to verify it responds with `{"field":"firstName",...}` — not a stack trace
3. Only then say you're ready

### Run
1. Hit wizard with just `opportunityId` — show it asks for `firstName`
2. Walk through each field — ask the user for answers, show numbered options for multipleChoice
3. Don't stop to ask permission between steps — just keep going
4. On submission, open candidate page in browser to verify
5. Opportunity is currently set to USA country questions (Gender, Ethnic Origin, Veteran, Disability)
6. Run wizard step by step with curl — each POST returns the next missing field:
```bash
BASE="https://localhost:5001/mordor/JobBoard/b316e881-cab2-999a-b0a0-838bfaaff491/QuickApplyWizard"
OPP="20badf49-0d7e-c88c-a5b6-070e96f79308"

# Step 1: just opportunityId → asks firstName
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'"}'

# Steps 2-5: add each field, POST again → asks next field
# firstName → lastName → phone → email → consent → country questions (4x) → resume → submitted

# Full submission in one shot:
curl -sk -X POST "$BASE" -H "Content-Type: application/json" \
  -d '{"opportunityId":"'"$OPP"'","firstName":"Demo","lastName":"Candidate","phone":"5551234567","email":"demo@test.com","candidateConsent":true,"countryQuestionAnswers":{"Gender":"Decline","Ethnic Origin":"Decline","Veteran":"Decline","Disability":"Decline"},"resumeAsked":true}'
```
4. Verify in recruiter UI:
   - Login: `https://localhost:5001/mordor/Test/SetLoginCookie?personId=77777941-1ab9-b0bb-247b-e302b1852410`
   - Candidate: `https://localhost:5001/mordor/Recruiter/CandidateDetail?candidateId={candidateId from response}`
5. Key talking points:
   - AI agent drives the conversation — wizard is stateless, agent accumulates answers
   - Country questions are dynamic from DB — no hardcoded options
   - Reuses existing domain services (same submission pipeline as QuickApplyController)
   - 300 lines of code, single controller

## Background processes
- dotnet: task b948bc3
- npm: task b738212
