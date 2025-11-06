---
id: task-32
title: Implement quality profile management and assignment system
status: Done
assignee: []
created_date: '2025-11-04 16:01'
updated_date: '2025-11-05 23:20'
labels:
  - quality
  - settings
  - admin
  - liveview
dependencies:
  - task-9
  - task-15
  - task-25.4
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build the quality profile management system that defines preferred qualities, file sizes, and upgrade rules for automatic downloads. Quality profiles are assigned to media items and used by automatic search to determine which releases to download.

The database schema for `quality_profiles` already exists (created in task-9), but there's no context module or UI for managing profiles. This task implements the full CRUD interface and profile application logic.

## Implementation Details

**Quality Profile Schema (Existing):**
```elixir
quality_profiles table:
  - id, name
  - min_size_mb, max_size_mb
  - preferred_quality (string: "1080p", "2160p", etc.)
  - allowed_qualities (list of allowed resolutions)
  - cutoff_quality (stop upgrading after reaching this)
  - upgrade_until_quality (upgrade releases until this quality)
  - preferred_tags (list: "PROPER", "REPACK", etc.)
  - blocked_tags (list: "CAM", "TS", etc.)
```

**Context Module: `Mydia.Settings.QualityProfiles`**
- Create/update/delete quality profiles
- List all profiles
- Get profile by ID
- Validate profile settings (min < max size, valid qualities)
- Check if a SearchResult matches a profile
- Score/rank SearchResults based on profile preferences

**Admin UI Integration:**
Add quality profiles tab to admin config page (task-15/25):
- List all quality profiles with summary
- Create/edit profile form with:
  - Name and description
  - Quality preferences (allowed, preferred, cutoff)
  - Size constraints (min/max MB)
  - Tag preferences and blacklist
  - Upgrade rules
- Delete profile (with confirmation if assigned to media)
- Duplicate profile for easier variant creation

**Profile Assignment:**
- Add `quality_profile_id` field to MediaItems (migration needed)
- Profile selector dropdown on media creation/edit
- Show assigned profile on media detail page
- Allow changing profile for existing media

**Profile Matching Logic:**
For a given SearchResult and QualityProfile, determine:
- Does it meet minimum requirements? (allowed quality, size range, no blocked tags)
- Is it preferred? (matches preferred quality, has preferred tags)
- Is it an upgrade? (better than current quality for that media item)
- Quality score (0-100) for ranking multiple matches

**Pre-defined Profiles:**
Create seed data with common profiles:
- "Any" - Any quality, no size limits
- "HD" - 720p/1080p, 1-10GB
- "Full HD" - 1080p only, 2-15GB  
- "4K" - 2160p, 15-80GB
- "SD" - 480p/DVD quality, under 2GB
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quality profile context module with CRUD operations
- [ ] #2 Quality profile validation (sizes, qualities, rules)
- [ ] #3 Admin UI tab for managing quality profiles
- [ ] #4 Create/edit profile form with all settings
- [ ] #5 List view showing all profiles with summary
- [ ] #6 Delete profile with validation (check if assigned)
- [ ] #7 Duplicate profile functionality
- [ ] #8 Match/score SearchResult against profile logic
- [ ] #9 Profile assignment on media items (add quality_profile_id field)
- [ ] #10 Profile selector on media create/edit forms
- [ ] #11 Show assigned profile on media detail page
- [ ] #12 Seed data with common pre-defined profiles
- [ ] #13 Profile matching considers: allowed qualities, size range, tags, upgrade rules
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Already Complete
- ✅ Database schema for quality_profiles exists
- ✅ QualityProfile Ecto schema exists  
- ✅ Settings context CRUD operations exist
- ✅ Default quality profiles module exists
- ✅ quality_profile_id field on MediaItems exists
- ✅ AdminConfigLive has basic quality profile CRUD UI

### Remaining Work

#### Stage 1: Fix Quality Profile Form (AC #3, #4, #5)
The current form doesn't match the schema. Need to update form to properly handle:
- qualities array field
- upgrades_allowed boolean
- upgrade_until_quality string
- rules map (min_size_mb, max_size_mb, preferred_sources, description)

#### Stage 2: Add Duplicate Profile Feature (AC #7)
- Add "Duplicate" button in quality profiles list
- Handle duplication with name suffix

#### Stage 3: Profile Assignment to Media (AC #9, #10, #11)
- Add quality profile selector to media create/edit forms
- Display assigned profile on media detail page

#### Stage 4: Profile Validation on Delete (AC #6)
- Check if profile is assigned to any media items before deletion
- Show appropriate error/confirmation message

#### Stage 5: Profile Matching Logic (AC #8, #13)
- Create module to match SearchResult against QualityProfile
- Implement scoring based on quality, size, source, upgrades
- Consider all profile rules in matching
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

All acceptance criteria have been met:

### What Was Already Complete
- ✅ AC #1: Quality profile context module with CRUD operations (already existed in Settings)
- ✅ AC #2: Quality profile validation (already existed in schema)
- ✅ AC #9: Profile assignment on media items (quality_profile_id field already existed)
- ✅ AC #10: Profile selector on media create/edit forms (already implemented)
- ✅ AC #11: Show assigned profile on media detail page (already implemented)
- ✅ AC #12: Seed data with pre-defined profiles (DefaultQualityProfiles module already existed)

### What Was Implemented
- ✅ AC #3, #4, #5: Fixed and enhanced Admin UI for managing quality profiles
  - Updated quality profile form to match actual schema (qualities array, upgrades_allowed, rules map)
  - Added proper field handling for all schema properties
  - Improved form layout with better organization and user experience
  
- ✅ AC #6: Delete profile with validation
  - Added profile_in_use?/1 function to check if profile is assigned to media items
  - Modified delete_quality_profile/1 to return {:error, :profile_in_use} when assigned
  - Updated UI to show helpful error message when deletion is blocked

- ✅ AC #7: Duplicate profile functionality
  - Added duplicate button in quality profiles list
  - Implemented duplicate_quality_profile event handler
  - Creates copy with (Copy) suffix

- ✅ AC #8, #13: Profile matching/scoring logic
  - Created new module Mydia.Settings.QualityMatcher
  - Implemented matches?/2 to check if SearchResult meets profile requirements
  - Implemented calculate_score/2 with weighted scoring (0-100)
  - Implemented is_upgrade?/3 to determine if result is better than current quality
  - Considers: allowed qualities, size constraints, preferred sources, upgrade rules

### Files Created
- lib/mydia/settings/quality_matcher.ex - Profile matching and scoring logic

### Files Modified
- lib/mydia/settings.ex - Added profile validation before delete
- lib/mydia_web/live/admin_config_live/index.ex - Enhanced quality profile handlers
- lib/mydia_web/live/admin_config_live/index.html.heex - Improved quality profile form
<!-- SECTION:NOTES:END -->
