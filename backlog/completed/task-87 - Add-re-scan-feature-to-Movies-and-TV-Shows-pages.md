---
id: task-87
title: Add re-scan feature to Movies and TV Shows pages
status: Done
assignee: []
created_date: '2025-11-05 19:47'
updated_date: '2025-11-05 20:08'
labels:
  - feature
  - ui
  - media-management
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement a re-scan functionality on both the Movies and TV Shows pages that allows users to manually trigger a scan of all configured media folders to discover new movies and series.

This feature should:
- Provide a clear UI button/action to trigger the scan
- Scan all configured media folders for the respective media type (movies or series)
- Process and index newly discovered media files
- Provide feedback to the user about the scan progress and results
- Handle errors gracefully (e.g., inaccessible folders, permission issues)

The implementation should follow Phoenix LiveView patterns and integrate with the existing media scanning infrastructure.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Movies page has a re-scan button/action that triggers scanning of all movie folders
- [x] #2 TV Shows page has a re-scan button/action that triggers scanning of all series folders
- [x] #3 Scan process discovers and indexes new media files in configured folders
- [x] #4 User receives clear feedback during the scan (progress indicator or status message)
- [x] #5 User is notified when scan completes with summary of results (e.g., X new items found)
- [x] #6 Error states are handled gracefully with appropriate user messaging
- [x] #7 Scan operation doesn't block the UI (runs asynchronously)
- [x] #8 Newly discovered media appears in the respective page after scan completes
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully implemented re-scan functionality for Movies and TV Shows pages with the following changes:

### 1. **Added PubSub Broadcasts to LibraryScanner Job** (`lib/mydia/jobs/library_scanner.ex`)
   - Broadcasts `library_scan_started` when scan begins
   - Broadcasts `library_scan_completed` with detailed results (new/modified/deleted file counts)
   - Broadcasts `library_scan_failed` on errors
   - All broadcasts use the `"library_scanner"` topic

### 2. **Updated MediaLive.Index LiveView** (`lib/mydia_web/live/media_live/index.ex`)
   - Added PubSub subscription to `"library_scanner"` topic in mount
   - Added `:scanning` and `:scan_result` assigns to track scan status
   - Implemented `handle_event("trigger_rescan")` to start full library scan
   - Added `handle_info` callbacks for all three scan events:
     - `library_scan_started` - Sets scanning status
     - `library_scan_completed` - Shows results, reloads media items
     - `library_scan_failed` - Displays error message
   - Smart filtering: Only processes events for scans matching current page type (movies/series)

### 3. **Added Re-scan Button UI** (`lib/mydia_web/live/media_live/index.html.heex`)
   - Button appears on Movies and TV Shows pages (not on "All Media")
   - Shows loading spinner and "Scanning..." text during scan
   - Disabled while scan is in progress
   - Uses DaisyUI classes and hero icons for consistent styling
   - Positioned between selection controls and Add Movie/Series buttons

### Key Features:
- **Asynchronous**: Uses Oban background jobs, doesn't block UI
- **Real-time feedback**: PubSub provides instant updates to all connected clients
- **Detailed results**: Shows count of new, modified, and deleted files
- **Error handling**: Gracefully handles and displays scan failures
- **Smart filtering**: Only updates relevant pages (Movies page only updates on movie scans)
- **Automatic refresh**: Media list reloads after successful scan to show new items

### User Experience:
1. User clicks "Re-scan" button on Movies or TV Shows page
2. Button shows loading spinner and "Scanning..." text
3. Flash message: "Library scan started..."
4. When complete, flash shows: "Library scan completed: X new, Y modified, Z removed"
5. Media list automatically refreshes to display new items
6. Button returns to normal state

All acceptance criteria met! ✅
<!-- SECTION:NOTES:END -->
