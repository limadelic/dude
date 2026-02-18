# Toggle Removal Plan: ApplicationIncorrectNameTextChanges

## Status
- **Branch**: `feature/PS-741409-rm-ApplicationIncorrectNameTextChanges`
- **PR**: #5270
- **CI**: Running (watching for failures with task bee06cb)
- **Phase**: Report (waiting for CI green)

## Next Steps
- [ ] CI passes
- [ ] Remove plan file from PR
- [ ] Merge or get review

## What It Does
Shows a React component (`ApplicationIncorrectNameTextContainer`) that warns applicants about which account they're using to apply. Prevents applying with wrong identity.

- **Enabled**: Shows React component with signOutUrl
- **Disabled**: Shows old translation text

## Files Affected

| File | Line | Change |
|------|------|--------|
| `ToggleableFeature.cs` | 335 | Remove constant |
| `CandidateController.cs` | 150 | Remove ViewBag assignment |
| `OpportunityApplyController.cs` | 282 | Remove ViewBag assignment |
| `_ContactInfoTemplates.cshtml` | 245-256 | Keep React component, remove if/else |
| `_ContactInfoTemplates.cshtml` | 510-521 | Keep React component, remove if/else |
| `CandidateControllerTests.cs` | 300-311 | Remove toggle test |
| `OpportunityApplyControllerTests.cs` | 905-916 | Remove toggle test |
| `FeaturePreviewDataTests.cs` | 109 | Remove from list |

## Code Changes

### _ContactInfoTemplates.cshtml (2 places)

**Before:**
```cshtml
@if (ViewBag.IsApplicationIncorrectNameTextChangesToggleEnabled)
{
    <react-ko-bridge ... />
}
else
{
    <p data-automation="title-supplement" ... />
}
```

**After:**
```cshtml
<react-ko-bridge
    params="component: 'Recruiting.Rct.Containers.Recruiter.OpportunityApply.ApplicationIncorrectNameTextContainer',
        props: { 'signOutUrl': $parent.signOutUrl}">
</react-ko-bridge>
```

### Controllers
Remove these lines:
- `CandidateController.cs:150` - `ViewBag.IsApplicationIncorrectNameTextChangesToggleEnabled = ...`
- `OpportunityApplyController.cs:282` - same

## Tests

### Remove (toggle-specific)
| File | Test Method |
|------|-------------|
| `CandidateControllerTests.cs:300-311` | ViewPresense_AddsIsApplicationIncorrectNameTextChangesToggleEnabledToViewBag |
| `OpportunityApplyControllerTests.cs:905-916` | Index_AddsIsApplicationIncorrectNameTextChangesToggleEnabledToViewBag |

### Keep (functionality)
| File | What It Tests |
|------|---------------|
| `ApplicationIncorrectNameTextContainer.tests.tsx` | React component renders correctly, shows modal on click, signout link works |

### Also Update (count-based tests)
| File | Change |
|------|--------|
| `FeatureToggleTests.cs:60` | Decrement toggle count from 238 to 237 |

### Lesson Learned
Searching for toggle name isn't enough - also check for count-based tests that track total toggles.

## Risk
Low - just making the new text permanent.
