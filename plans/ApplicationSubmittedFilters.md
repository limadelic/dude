# Toggle Removal Plan: ApplicationSubmittedFilter + ApplicationSubmittedFilterReindex

## What It Does
Controls the "Application Submitted" filter on the People/Candidates page. Both toggles must be enabled for feature to work. Removing both makes the feature permanent.

## Files Affected

| File | Change |
|------|--------|
| `ToggleableFeature.cs:313-314` | Remove both constants |
| `FeaturePreviewDataTests.cs:56-57` | Remove both from list |
| `FeatureToggleTests.cs:60` | Decrement count 238 → 236 |
| `Candidates.cshtml:520-524` | Remove toggle check, keep feature code |
| `Candidates_Ignite.cshtml:87-91` | Remove toggle check, keep feature code |
| `FilterDrawerContainer.tsx:231-238` | Remove if block, always add filter |
| `RecruiterBrowsesCandidates.cs` | Remove both from TestTenantToggle attributes (8 places) |
| `RecruiterBrowsesCandidatesIgnite.cs` | Remove both from TestTenantToggle attributes (5 places) |
| `HiringManagerBrowsesCandidates.cs` | Remove both from TestTenantToggle attributes (2 places) |

## Code Changes

### View files (cshtml)
```js
// Before
var isApplicationFilterEnabled = Recruiting.TenantFeatureToggle.isEnabled('@ToggleableFeature.ApplicationSubmittedFilter') && Recruiting.TenantFeatureToggle.isEnabled('@ToggleableFeature.ApplicationSubmittedFilterReindex');
if (isApplicationFilterEnabled) {
    filterTypes[2].Value.splice(0, 0, {
        Text: $.t("..."), Key: "ApplicationsSubmitted"
    });
}

// After
filterTypes[2].Value.splice(0, 0, {
    Text: $.t("..."), Key: "ApplicationsSubmitted"
});
```

### FilterDrawerContainer.tsx
```ts
// Before
if(Recruiting.TenantFeatureToggle.isEnabled("ApplicationSubmittedFilter") && Recruiting.TenantFeatureToggle.isEnabled("ApplicationSubmittedFilterReindex")){
    filterTypes.push({...});
}

// After
filterTypes.push({
    Text: $.t("Recruiter.Candidates.Filters.ApplicationsSubmittedIgnite"),
    Value: [
        { Text: $.t("Recruiter.Candidates.Filters.ApplicationsSubmittedIgnite"), Key: "ApplicationsSubmitted", Type: "RadioButton" }
    ]
});
```

### Test attributes
```csharp
// Before
[TestTenantToggle(ToggleableFeature.ApplicationSubmittedFilter, ToggleableFeature.ApplicationSubmittedFilterReindex, ToggleableFeature.ReindexCandidateTags)]

// After
[TestTenantToggle(ToggleableFeature.ReindexCandidateTags)]

// Or if those were the only toggles:
// Before
[TestTenantToggle(ToggleableFeature.ApplicationSubmittedFilter, ToggleableFeature.ApplicationSubmittedFilterReindex)]

// After - remove attribute entirely
```

## Tests

### Unit Tests
| File | Action | Notes |
|------|--------|-------|
| `FeatureToggleTests.cs:60` | Update | Decrement count by 2 |
| `FeaturePreviewDataTests.cs` | Update | Remove both toggles from list |

### Integration Tests
None affected.

### System Tests
| File | Action | Notes |
|------|--------|-------|
| `RecruiterBrowsesCandidates.cs` | Update | Remove toggles from TestTenantToggle (8 places) |
| `RecruiterBrowsesCandidatesIgnite.cs` | Update | Remove toggles from TestTenantToggle (5 places) |
| `HiringManagerBrowsesCandidates.cs` | Update | Remove toggles from TestTenantToggle (2 places) |

### Functionality Tests (Keep - must pass)
| File | What It Tests |
|------|---------------|
| `RecruiterBrowsesCandidates.cs` | People page filtering functionality |
| `RecruiterBrowsesCandidatesIgnite.cs` | People page filtering (Ignite) |
| `HiringManagerBrowsesCandidates.cs` | Hiring manager browse candidates |

## System Test Verification

Trove run: `699e0d9bbf7f18f3d0e2e28c` (System-Tests-Person)

| Test Class | Status | Details |
|------------|--------|---------|
| RecruiterBrowsesCandidates (all subclasses) | PASS | ~20 tests, all passed including filter tests |
| RecruiterBrowsesCandidatesIgnite (all subclasses) | PASS | ~10 tests, all passed |
| HiringManagerBrowsesCandidates (subclasses 1-4) | PASS | 2 infra failures only (725s timeout = Selenium grid, not our code): `part2` and `part4` |
| HiringManagerBrowsesCandidatesIgnite | PASS | All passed |

Failed tests NOT caused by our change:
- `HiringManagerBrowsesCandidates3.part2` — WebDriver timeout 180s (`rec-ggr.dlas1.ucloud.int`)
- `HiringManagerBrowsesCandidates3.part4` — WebDriver timeout 180s
- `RecruiterBrowsesCandidates_OFCCP.SearchBannerVisibleWhenSearching` — Browser interaction timeout 40s

## CI Summary

| Check | Status |
|-------|--------|
| Unit Tests 1/2/3 | PASS |
| Integration Tests 1/2/3 | PASS |
| JS Tests | PASS |
| Sonar / Schema | PASS |
| System Tests (affected) | PASS (infra flakes only) |

## Risk
Low - feature becomes permanently enabled.
