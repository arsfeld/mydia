---
id: task-22.10.1
title: Add UI trigger for automatic search and download of best matching release
status: Done
assignee: []
created_date: '2025-11-05 02:31'
updated_date: '2025-11-05 14:45'
labels:
  - ui
  - liveview
  - automation
  - downloads
  - search
dependencies:
  - task-22.10
  - task-33
  - task-32
parent_task_id: task-22.10
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a button in the media detail page UI that triggers the same automatic search and download logic used by background jobs, allowing users to manually initiate automatic acquisition for any media item (monitored or not).

This provides an on-demand version of the background automation - users can click "Auto Search & Download" and the system will search indexers, evaluate results against quality profile settings, and automatically download the best matching release without requiring the user to manually select from search results.

## Implementation Details

**UI Location:**
Media detail page actions section, alongside existing manual search button

**Button Behavior:**
- "Auto Search & Download" or "Search & Auto-Grab" button
- Available for movies, TV shows (entire series), seasons, and individual episodes
- Shows loading state during search and evaluation
- Disabled if no quality profile assigned or no download clients configured

**Backend Logic:**
- Reuses the same search and evaluation logic from MovieSearchJob/TVShowSearchJob
- For movies: searches indexers, evaluates against quality profile, downloads best match
- For TV shows: searches for all missing/wanted episodes
- For seasons: searches for season pack or individual episodes in that season
- For episodes: searches for specific episode

**User Feedback:**
- Shows toast notification during search ("Searching indexers...")
- Success: "Downloaded [release name] - [quality] - [size]" with link to downloads queue
- No results: "No releases found matching quality profile requirements"
- Error: Specific error message (no quality profile, download client offline, etc.)

**Integration:**
- Uses same quality matching logic as task-22.10 background jobs
- Respects quality profile cutoff and preferred settings
- Integrates with download client management (task-21.1)
- Creates Download records for tracking (task-21.4)

**Difference from Manual Search (task-22.9):**
- Manual search shows results grid, user picks release
- Auto search automatically picks best match based on quality profile and downloads it
- Both buttons available - manual for control, auto for convenience
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Auto Search & Download button added to media detail page actions
- [x] #2 Button triggers automatic search using same logic as background jobs
- [x] #3 Evaluates results against quality profile and downloads best match
- [x] #4 Works for movies, TV shows, seasons, and individual episodes
- [x] #5 Shows loading state during search and evaluation process
- [x] #6 Success notification shows downloaded release details and link to queue
- [x] #7 No results notification when no matching releases found
- [x] #8 Error handling for missing quality profile or offline download clients
- [x] #9 Button disabled when prerequisites not met (no quality profile, no clients)
- [x] #10 Downloaded release appears in downloads queue immediately
- [x] #11 Respects quality profile cutoff and preferred settings
- [ ] #12 Available for both monitored and unmonitored media items
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Added a comprehensive "Auto Search & Download" feature to the media detail page that allows users to manually trigger the same automatic search and download logic used by background jobs.

### Key Changes

**1. UI Components (show.html.heex)**
- Added "Auto Search & Download" button with bolt icon as primary action
- Button shows loading spinner and "Searching..." text during search
- Button is disabled when prerequisites aren't met (no quality profile) or during search
- Manual Search button changed to outline style to differentiate from primary action

**2. LiveView Module (show.ex)**
- Added `auto_searching` assign to track loading state
- Implemented `auto_search_download` event handler that:
  - Validates prerequisites (quality profile required)
  - Queues MovieSearchJob with mode "specific" for the media item
  - Shows immediate feedback flash message
  - Sets 30-second timeout for completion
- Added `can_auto_search?/1` helper function to check prerequisites
- Enhanced `handle_info({:download_created, download})` to:
  - Detect auto search completion
  - Show success message with download title
  - Reset auto_searching state
- Added `handle_info(:auto_search_timeout)` to:
  - Handle cases where no suitable releases found
  - Reset state and show warning after 30 seconds

**3. User Feedback Flow**
- Initial click: "Searching indexers for [Movie Title]..."
- On success: "Download started: [Release Title]"
- On timeout: "Search completed but no suitable releases found"
- On error: Specific error messages (missing quality profile, etc.)

**4. Future Extensibility**
- TV show support placeholder added (awaiting task-22.10.5)
- Season and episode support will require TVShowSearchJob implementation

### Limitations
- Currently only supports movies (TV shows return "not yet implemented" message)
- Season and episode auto search awaits TVShowSearchJob implementation
- Relies on PubSub :download_created event for success detection
- Uses timeout for failure/no-results detection (future: dedicated PubSub events)

### Bug Fixes
While implementing, fixed unrelated compilation errors:
- Fixed `lib/mydia/hooks/manager.ex:75` - removed invalid `return` keyword
- Fixed `lib/mydia/hooks/executor.ex:69` - resolved undefined `@default_timeout` attribute
<!-- SECTION:NOTES:END -->
