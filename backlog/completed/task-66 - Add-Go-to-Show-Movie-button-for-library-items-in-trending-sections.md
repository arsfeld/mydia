---
id: task-66
title: Add "Go to Show/Movie" button for library items in trending sections
status: Done
assignee: []
created_date: '2025-11-05 05:02'
updated_date: '2025-11-05 05:08'
labels:
  - enhancement
  - dashboard
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When items in trending movies or trending TV shows are already in the user's library (in_library: true), replace the "Add to Library" button with a "Go to Movie" or "Go to Show" button that navigates to the media detail page.

Currently, when an item is in the library, it only shows a badge indicating library status but no action button. Users should be able to quickly navigate to the detail page for items they already have in their library.

## Implementation Details

- In dashboard template, when `movie.in_library` is true, show a button/link that navigates to the movie detail page
- In dashboard template, when `show.in_library` is true, show a button/link that navigates to the TV show detail page
- Button should use appropriate styling (e.g., `btn-ghost` or `btn-outline`) to distinguish it from the "Add to Library" primary action
- Use `<.link navigate={...}>` for navigation
- Ensure the navigation uses the correct route helper and passes the appropriate media item identifier
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Trending movies that are in library show 'Go to Movie' button instead of 'Add to Library'
- [x] #2 Trending TV shows that are in library show 'Go to Show' button instead of 'Add to Library'
- [x] #3 Clicking the button navigates to the correct media detail page
- [x] #4 Button styling is visually distinct from the 'Add to Library' button
- [x] #5 Library status badge remains visible alongside the navigation button
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Updated the dashboard to show "Go to Movie" and "Go to Show" buttons for library items in trending sections:

1. **Modified `Mydia.Media.get_library_status_map/0`** (lib/mydia/media.ex:175-184):
   - Added `id` field to the library status map to include the database ID
   - Updated documentation to reflect the new field

2. **Updated `MydiaWeb.DashboardLive.Index.enrich_with_library_status/2`** (lib/mydia_web/live/dashboard_live/index.ex:180-191):
   - Added `id` field to enriched items from the library status map
   - Also updated the library status map update logic when adding new items (line 146)

3. **Modified dashboard template** (lib/mydia_web/live/dashboard_live/index.html.heex):
   - Added "Go to Movie" button for movies in library (lines 126-129)
   - Added "Go to Show" button for TV shows in library (lines 210-213)
   - Both buttons use `btn-ghost` styling to distinguish from primary "Add to Library" action
   - Navigation uses `/movies/:id` and `/tv/:id` routes respectively

The implementation ensures that users can now quickly navigate to detail pages for media already in their library, improving the user experience and making the dashboard more actionable.
<!-- SECTION:NOTES:END -->
