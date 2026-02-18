# Current: PS-741409 Toggle Removal

Branch: `feature/PS-741409-remove-toggles`

## Constraints
- No LDtoggle (too much work)
- Application team toggles

## Toggles to Remove
1. [x] ApplicationIncorrectNameTextChanges - PR #5270, CI green, base=main
2. [~] ApplicationSubmittedFilter + ApplicationSubmittedFilterReindex - PR #5279, CI running, base=main
3. [~] AssessmentIntegration - PR #5301, CI round 4 running, base=main
4. [ ] AssessmentLinkRequestOpp

## PRs (both target main directly)
- PR #5270 - ApplicationIncorrectNameTextChanges (watching: b3f8259)
- PR #5279 - ApplicationSubmittedFilters (watching: be68928)
- PR #5301 - AssessmentIntegration (watching: 12d2f7a)

## Plans
Plans are now in PR descriptions (not separate files).
Full plan also at: ~/.claude/plans/AssessmentIntegration.md

## AssessmentIntegration Status (PAUSED)

### Branch
`feature/PS-741409-rm-AssessmentIntegration` off main

### What's done
- All production code cleaned (15 controllers, 3 services/mappers, 1 domain model, 16 Razor views)
- Toggle constant removed from ToggleableFeature.cs
- FeaturePreviewDataTests toggle count updated (238→237)
- Opportunity.Clone() param removed, FromAssessmentStatus() param removed
- All system test TestTenantToggle attributes removed (19 files)
- Unit test mock setup fixes across 4 rounds of CI

### Commits on branch
1. `Remove AssessmentIntegration toggle` - 72 files, +502/-1307
2. `Fix tests after toggle removal` - 6 files
3. `Fix test setup after toggle removal` - 5 files
4. `Fix null safety and test mocks` - 4 files (includes real bug fix: RecruiterController.cs Assessments?.Any())

### CI Status (round 4, commit 12d2f7a)
- Unit Tests 1, 2, 3: running (rounds 1-3 had cascading mock failures, each round fixed more)
- Integration Tests: not yet run this round
- System Tests: OUT OF SCOPE (known flaky, don't chase)
- Previous rounds: UT2+UT3 went green in round 3, UT1 still had IndeedApplyV2Controller + RecruiterController failures

### If CI fails again
- Pattern is always the same: assessment code no longer behind toggle, test didn't mock assessment dependencies
- Check `assessmentDomainService.GenerateOrRetrieveAssessmentsForApplication` mock in test setup
- Check `candidate.Candidate.Assessments` returns non-null collection
- Check `applicationRepository.GetAllByCandidate` returns non-null array
- Check `opportunityAssessmentPackageDtoMapper.ToOpportunityAssessmentPackages` returns success
- Check `opportunity.SetAssessments` returns success

### Workflow verification (blocked)
- Toggle verified enabled for all tenants Feb 9 (runs 21843204907-21843259765, all 4 DCs)
- "Tenant Feature - List Enabled For All" workflow currently broken (GCP IAM permission issue)
- Tracked separately, not blocking this PR

## Process (per toggle)
1. Plan: find usages, assess impact, identify affected tests
2. Remove toggle checks (keep enabled path)
3. Remove constant from ToggleableFeature.cs
4. Fix tests
5. Run tests
6. Generate PR targeting main
