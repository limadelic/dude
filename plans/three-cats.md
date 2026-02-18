# Three Cats (trois chats)

## The Three Cats

- **AIVA** (ProPeopleCandidateAssistAgent) + AIVAChatBot — candidate-facing, job board, floating drawer
- **Ruth** (ProPeopleCandidateSourcingAgent) + CandidateSourcing/Bryte Chat — recruiter-facing, modal
- **IQ** (ProPeopleInterviewScoreCardQuestionsAgent) + ScorecardWithBryte — recruiter-facing

## What Each Cat Brings

- **IQ** — precedent: interactive components inside chat (selectable chips, action buttons, `getJsonFromText()` + type dispatch)
- **AIVA** — target: candidate-facing, where Enigma lives, where the changes go
- **Ruth** — patterns: parser chain, message detection, component dispatch

No single cat has the full picture. Pull from all three to upgrade AIVA.

## Files

- **AIVA** — `Containers/JobBoard/AIVAChatBot.tsx`
- **Ruth** — `Containers/OpportunityApplicants/CandidateSourcing/`
- **IQ** — `Containers/Recruiters/Bryte/ScorecardWithBryte.tsx`

## Rendering Pipelines

### Ruth (parser chain)
```
Agent response → adapt() → candidateParser → actionParser → mdParser
  → MessageContent.detect() → CandidatesMessage or MdMessage
```

### IQ (inline type dispatch)
```
Agent response → getJsonFromText() → check first key:
  "job_skills_suggestions" / "behavior_skills_suggestions" → UkgChip array (selectable)
  "scorecard" / "scorecardFinal" → InterviewScorecardPreviewModal + action buttons
  else → plain text message
```

## Question Types (from `CountryQuestionDisplayType` + `ScreeningQuestionType`)

| Question Type | Ignite Component |
|---|---|
| Text | chat input |
| Numeric | chat input |
| Phone | chat input |
| MultipleChoice | `UkgRadioGroup` / `UkgRadioButton` |
| Boolean (yes/no) | `UkgRadioGroup` / `UkgRadioButton` |
| MultiSelect | `UkgCheckbox` (multiple) |
| Date | `UkgDatePicker` |
| Info | static text (read-only, no input needed) |

## The Gap

- Nobody has put `UkgRadioGroup`, `UkgCheckbox`, or `UkgDatePicker` inside a chat bubble
- Form-in-chat components are net-new to this codebase

## Stories (3)

- Radio in chat — MultipleChoice + boolean (`UkgRadioGroup`)
- Checkbox group in chat — MultiSelect (`UkgCheckbox`)
- Date picker in chat — Date (`UkgDatePicker`)

All three need Ruth's parser/detect/dispatch pattern brought into AIVA + IQ's JSON detection.
Text/numeric/phone/info already covered by chat input and static text.
AIVA is POC-level code — this is the painful part.
