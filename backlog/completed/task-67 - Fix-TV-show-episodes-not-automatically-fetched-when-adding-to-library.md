---
id: task-67
title: Fix TV show episodes not automatically fetched when adding to library
status: Done
assignee: []
created_date: '2025-11-05 14:24'
updated_date: '2025-11-05 14:43'
labels:
  - bug
  - tv-shows
  - metadata
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When adding a TV show to the library through any method (dashboard, search, manual add), the episodes are not automatically fetched from the metadata provider. Users must manually click "Refresh Metadata" to fetch the episode list.

**Expected behavior**: Episodes should be automatically fetched when a TV show is added to the library.

**Current behavior**: Episodes are only fetched when the user manually clicks "Refresh Metadata" on the show detail page.

**Affected workflows**:
- Adding TV show from dashboard (trending, etc.)
- Adding TV show from search results
- Any other TV show addition method

**Workaround**: Users can click "Refresh Metadata" to fetch episodes after adding the show.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Episodes are automatically fetched when adding a TV show from the dashboard
- [x] #2 Episodes are automatically fetched when adding a TV show from search results
- [x] #3 Episodes are automatically fetched for any TV show addition workflow
- [x] #4 User should not need to manually click 'Refresh Metadata' to see episodes
- [x] #5 Existing manual refresh functionality still works as a fallback
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Fixed the issue where TV show episodes were not automatically fetched when adding shows to the library.

**Changes Made**:

1. **search_live/index.ex** (lines 720-738 and 227-238):
   - Modified `create_media_item_from_metadata/2` to call `Media.refresh_episodes_for_tv_show/2` for ALL TV shows
   - Modified manual add flow to also fetch episodes for TV shows
   - Episodes are fetched regardless of monitored status (monitored is for tracking/downloading, not metadata fetching)
   - Now fetches all seasons/episodes using the existing robust episode fetching logic

2. **library/metadata_enricher.ex** (lines 105-116):
   - Modified `create_new_media_item/4` to call `Media.refresh_episodes_for_tv_show/2` after creating TV show media items
   - Episodes are fetched regardless of monitored status
   - Ensures episodes are fetched during library scans

3. **test/support/factory.ex** (lines 51-59):
   - Fixed Download factory to use correct schema fields after recent migration
   - Removed deprecated `:status` and `:progress` fields
   - Added required `:download_client` field

**Technical Approach**:
- Used the existing `Media.refresh_episodes_for_tv_show/2` function instead of duplicating logic
- This function handles edge cases like season 0, missing episodes, and error handling
- **CRITICAL**: Episodes are ALWAYS fetched for TV shows, regardless of monitored status
- The monitored flag is about whether to track/download the show, NOT about fetching metadata

**Testing**:
- All Media context tests pass (13/13)
- Changes are syntactically correct
- Changes align with existing patterns in dashboard_live and add_media_live
<!-- SECTION:NOTES:END -->
