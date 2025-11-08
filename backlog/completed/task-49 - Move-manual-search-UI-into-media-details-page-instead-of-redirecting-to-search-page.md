---
id: task-49
title: >-
  Move manual search UI into media details page instead of redirecting to search
  page
status: Done
assignee: []
created_date: '2025-11-04 21:49'
updated_date: '2025-11-04 21:57'
labels:
  - enhancement
  - ui
  - ux
  - search
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, clicking "Manual Search" on the media details page redirects to the main search page with a pre-filled query. This workflow is disruptive and doesn't work well for users who want to search for alternative releases for a specific media item.

## Problem
- Redirecting to the search page loses context of the media details view
- Users have to navigate back after initiating a download
- The search page is designed for discovery, not for finding alternatives for existing media
- Episode-level searches also redirect away from the context

## Proposed Solution
Integrate the manual search functionality directly into the media details page:
- Add a "Manual Search" section/modal that displays search results inline
- Keep the user on the media details page throughout the workflow
- Search results should show download options specific to this media item
- For TV shows, support both show-level and episode-level manual searches
- After initiating a download, user remains in context to see the download appear in the history

## Implementation Considerations
- Could use a modal with search results table
- Could use an expandable section on the page
- Search results should integrate with existing download initiation flow
- Should pre-populate search query based on media item metadata (title, year, season/episode)
- Consider showing only relevant results (matching quality profiles, etc.)

## Benefits
- Better user experience with contextual workflows
- Easier to compare search results with existing files
- Can see download history update immediately
- No navigation disruption

## Related
- Currently implemented in task-43.1 (redirects to search page)
- Related to task-29 (download initiation from search results)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Manual search button opens inline search UI on media details page
- [x] #2 Search results display within media details context (modal or section)
- [x] #3 User can initiate downloads from inline search results
- [x] #4 User remains on media details page throughout the workflow
- [x] #5 Episode-level manual search also works inline
- [x] #6 Download history updates immediately after initiating download
- [x] #7 Search query is pre-populated from media item metadata
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully moved manual search UI into the media details page. Users now stay in context when searching for alternative releases.

### Key Changes:

**1. Added search state to MediaLive.Show (`lib/mydia_web/live/media_live/show.ex`)**
- Added assigns for modal state, search query, search context, and filters
- Configured stream for search results

**2. Implemented search event handlers:**
- `manual_search` - Opens modal and triggers search for media item
- `search_episode` - Opens modal and triggers search for specific episode
- `close_manual_search_modal` - Closes modal and resets state
- `filter_search` - Applies quality and seeder filters
- `sort_search` - Sorts results by quality, seeders, size, or date
- `download_from_search` - Initiates download directly from results

**3. Added async search handler:**
- Processes search results asynchronously
- Filters and sorts results based on user preferences
- Updates UI with results or empty state

**4. Created comprehensive modal UI (`lib/mydia_web/live/media_live/show.html.heex`)**
- Full-screen modal with header showing context
- Search query display
- Filter panel (quality, min seeders)
- Sort options (quality, seeders, size, date)
- Results table with quality badges, health indicators, and download buttons
- Loading and empty states

**5. Download integration:**
- Creates download records directly from search results
- Associates downloads with media item or specific episode
- Downloads appear in download history immediately via PubSub
- User never leaves the media details page

### Benefits:
- No navigation disruption
- Contextual workflow keeps user focused
- Download history updates automatically
- Works for both show-level and episode-level searches
- Consistent UI with existing search page
<!-- SECTION:NOTES:END -->
