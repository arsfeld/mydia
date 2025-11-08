---
id: task-69
title: Fix episodes with N/A air date incorrectly showing as missing
status: Done
assignee: []
created_date: '2025-11-05 14:29'
updated_date: '2025-11-05 14:35'
labels:
  - bug
  - tv-shows
  - episodes
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Episodes that have an air date of "N/A" (typically special episodes or episodes without confirmed air dates) are currently being marked as missing in the UI. These episodes should be handled differently since they don't have a confirmed air date and shouldn't be treated as "missing" content.

The issue likely occurs in the episode status logic that determines whether an episode should be marked as missing based on its air date being in the past.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Episodes with N/A or null air dates are not marked as missing
- [x] #2 Episode status logic correctly handles missing/null air dates
- [x] #3 UI clearly indicates when an episode has no confirmed air date
- [x] #4 Missing episode detection only applies to episodes with past confirmed air dates
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Root Cause Analysis

The bug is in `/home/arosenfeld/Code/mydia/lib/mydia/media/episode_status.ex:68-79`.

The `get_episode_status_with_downloads/1` function has a pattern matching issue:
- Line 68: First clause only matches episodes where `air_date is NOT nil` (`when not is_nil(air_date)`)
- Line 79: Catch-all clause handles episodes with nil air_date
- The catch-all immediately calls `check_downloads/1` which returns `:missing` for episodes with no active downloads

**Result**: Episodes with N/A (null) air dates are incorrectly marked as "missing".

## Implementation Plan

### Stage 1: Fix Episode Status Logic
**Goal**: Add proper handling for episodes with nil air dates
**Files**: `lib/mydia/media/episode_status.ex`
**Changes**:
- Add a new pattern match clause to handle episodes with nil air dates
- Episodes with nil air dates should be treated as "TBA" (To Be Announced) rather than missing
- Only mark episodes as missing if they have a confirmed past air date AND no downloads/media files

### Stage 2: Update UI Display
**Goal**: Ensure UI clearly shows when episodes have no confirmed air date
**Files**: `lib/mydia_web/live/media_live/show.html.heex`
**Changes**:
- Add UI indicators for episodes with N/A air dates
- Use appropriate status label (e.g., "TBA" or "No Air Date")
- Verify status colors and icons are appropriate

### Stage 3: Test the Fix
**Goal**: Verify the fix works correctly
**Tests**:
- Manually test with episodes that have nil air dates
- Verify they're no longer marked as missing
- Check UI display is correct
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully fixed the bug where episodes with N/A (null) air dates were incorrectly showing as missing.

### Changes Made

1. **Added new `:tba` status type** in `lib/mydia/media/episode_status.ex`:
   - Updated the `@type status` to include `:tba`
   - Added pattern match in `get_episode_status/1` to return `:tba` for episodes with nil air_date
   - Added pattern match in `get_episode_status_with_downloads/1` to return `:tba` for episodes with nil air_date

2. **Added UI helpers for `:tba` status**:
   - `status_color(:tba)` returns `"badge-warning"` (yellow/warning color)
   - `status_icon(:tba)` returns `"hero-question-mark-circle"` icon
   - `status_label(:tba)` returns `"TBA"` label

3. **Updated `status_details/1` function** to properly handle nil air dates:
   - Modified the function with `downloads` list to check for nil air_date before marking as missing
   - Returns "Air date to be announced" for episodes with nil air_date
   - Ensures nil air date episodes are not marked as "Missing"

4. **Added comprehensive tests** in `test/mydia/media/episode_status_test.exs`:
   - Tests for `get_episode_status/1` with nil air dates
   - Tests for `get_episode_status_with_downloads/1` with nil air dates
   - Tests for all UI helpers (color, icon, label)
   - Tests for `status_details/1` with nil air dates
   - All 12 tests pass successfully

### Files Modified

- `lib/mydia/media/episode_status.ex` - Core logic fix
- `test/mydia/media/episode_status_test.exs` - New test file

### Result

Episodes with N/A air dates now:
- Show as "TBA" status with yellow badge
- Display "Air date to be announced" in details
- Are no longer incorrectly marked as "Missing"
- Only episodes with confirmed past air dates AND no downloads/media files are marked as missing
<!-- SECTION:NOTES:END -->
