# Toggle Removal: AssessmentIntegration

## Status: Planning

## What it does
Dev toggle for WOTC/Assessments UI - controls visibility of assessment integration features

## Production Code (3 files)
- `Product/Recruitment.Application.Services/DtoMappers/BaseCreateOpportunityDtoMapper.cs` - IsEnabled check
- `Product/Recruitment.Application.Services/DtoMappers/ApplicationSubmissionDtoMapper.cs` - IsEnabled check (negated)
- `Product/Recruitment.Application.Services/Services/RecruitmentModule/Services/IndeedApplyService.cs` - IsEnabled check

## Unit Tests (need mock updates)
- ApplicationSubmissionDtoMapperTests.cs
- CreateOpportunityDtoMapperTests.cs (multiple test methods)
- IndeedApplyServiceTests.cs
- IndeedApplyV2ControllerTests.cs
- ApplicationV2ControllerTests.cs
- OpportunityApplyControllerTests.cs
- FeaturePreviewDataTests.cs (toggle count + list)

## System Tests (need TestTenantToggle attribute removal)
- RecruiterViewsApplicationsWithAssessments.cs (3 classes)
- RecruiterViewsApplicationsWithGenericAssessments.cs (2 classes)
- RecruiterSavesFilterGroups.cs (2 classes)
- RecruiterViewsAssessmentsOnCandidateDetailsPage.cs (1 class)
- RecruiterViewsAssessmentsOnCandidateDetailsPageIgnite.cs (1 class)
- RecruiterFiltersApplicantsByAssessmentIntegrationAssessmentScore.cs (3 classes)
- RecruiterManagesAssessments.cs (13+ classes)

## System Test Verification

**STATUS: PARTIALLY VERIFIED — System-Tests-Application was CANCELLED. Most affected tests not run.**

| Test Class | Suite | Status | Notes |
|------------|-------|--------|-------|
| RecruiterViewsAssessmentsOnCandidateDetailsPage | Person | PASS | Trove 699e2347...083e08 |
| RecruiterViewsAssessmentsOnCandidateDetailsPageIgnite | Person | PASS | Trove 699e2347...083e08 |
| RecruitmentAdministratorManagesNewAssessmentIntegrations (5 tests) | Platform | PASS | Trove 699e3795...1aa1fc |
| RecruiterViewsApplicationsWithAssessments (3 classes) | Application | NOT RUN | Job cancelled |
| RecruiterViewsApplicationsWithGenericAssessments (2 classes) | Application | NOT RUN | Job cancelled |
| RecruiterSavesFilterGroups (2 classes) | Application | NOT RUN | Job cancelled |
| RecruiterFiltersApplicantsByAssessmentIntegrationAssessmentScore (3 classes) | Application | NOT RUN | Job cancelled |
| RecruiterManagesAssessments (13+ classes) | Application | NOT RUN | Job cancelled |
| RecruiterManagesAssessmentsIgnite | Application | NOT RUN | Job cancelled |
| CandidateAppliesToAnOpportunityWithAssessmentIntegrationToggleOn | Application | NOT RUN | Job cancelled |
| CandidateViewsApplicationAssessments | Application | NOT RUN | Job cancelled |
| RecruiterSortsApplicantListByGenericAssessmentStatus | Application | NOT RUN | Job cancelled |
| RecruiterManagesColumnComponentIgnite | Application | NOT RUN | Job cancelled |

Note: 3rd-Party suite had 5 assessment failures but those are NOT in our modified files (LegacyAssessmentVendor/Outmatch tests). Errors are infra timeouts ("Assess did not respond in a timely manner").

## CI Summary

| Check | Status |
|-------|--------|
| Unit Tests 1/2/3 | PASS |
| Integration Tests 1/2/3 | PASS |
| JS Tests | PASS |
| Sonar / Schema | PASS |
| System Tests (affected) | NOT RUN — needs re-run |

## Complexity
HIGH - Many files and tests affected

## Next Steps
1. Verify toggle is enabled for all tenants (run workflow)
2. Remove toggle checks from 3 production files
3. Update unit test mocks (remove toggle setup, assume always enabled)
4. Remove TestTenantToggle attributes from system tests
5. Update FeatureToggleTests count
6. Remove from FeaturePreviewDataTests list
7. Remove constant from ToggleableFeature.cs
