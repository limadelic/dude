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
