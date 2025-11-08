---
id: task-78
title: Add re-scan metadata button for movies and TV shows
status: Done
assignee: []
created_date: '2025-11-05 15:59'
updated_date: '2025-11-05 18:27'
labels:
  - enhancement
  - ui
  - metadata
  - media-files
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Overview
Add UI controls to manually trigger file metadata re-scanning for movies and TV shows. This allows users to refresh technical metadata (resolution, codec, audio, etc.) for their media files without re-importing.

## Current Situation
- The `Mydia.Library.refresh_file_metadata/1` functions exist and work correctly
- There's no UI to trigger these functions
- Users cannot manually refresh metadata for existing files

## Proposed Solution

### 1. Movie/TV Show Detail Page
Add a "Refresh File Metadata" button on the media detail page (where files are displayed):

**Location**: Near the media files section, possibly in the card header or as an action button

**Behavior**:
- Triggers `Library.refresh_file_metadata/1` for each media file
- Shows loading state while scanning
- Displays success/error toast messages
- Updates displayed metadata in real-time after completion
- For TV shows, option to refresh all episodes or just current season

**UI Considerations**:
- Icon: refresh/reload icon (heroicon-arrows-path or similar)
- Tooltip: "Re-scan file metadata"
- Disabled state while scanning is in progress
- Show progress if multiple files (e.g., "Scanning 3 of 10 files...")

### 2. Bulk Actions (Optional Enhancement)
Consider adding bulk operations:
- "Refresh All Media Files" in Library Settings
- Batch operation for selected media items
- Background job for scanning entire library

### 3. LiveView Implementation
**Handle Event**:
```elixir
def handle_event("refresh_file_metadata", %{"file_id" => file_id}, socket) do
  case Library.refresh_file_metadata_by_id(file_id) do
    {:ok, updated_file} ->
      {:noreply, 
       socket
       |> put_flash(:info, "File metadata refreshed successfully")
       |> reload_media_files()}
    
    {:error, reason} ->
      {:noreply, put_flash(:error, "Failed to refresh: #{reason}")}
  end
end
```

**For bulk refresh (all files for a media item)**:
```elixir
def handle_event("refresh_all_files", %{"media_item_id" => id}, socket) do
  media_files = Library.get_media_files_for_item(id)
  
  # Could use Task.async_stream for progress tracking
  results = Enum.map(media_files, &Library.refresh_file_metadata/1)
  
  success_count = Enum.count(results, &match?({:ok, _}, &1))
  
  {:noreply,
   socket
   |> put_flash(:info, "Refreshed #{success_count} file(s)")
   |> reload_media_files()}
end
```

### 4. UI Feedback
Show before/after comparison or indication:
- Highlight which fields were updated
- Show timestamp of last metadata refresh (verified_at)
- Display warning if FFprobe is not available (falling back to filename)

## Technical Considerations
- **Performance**: Scanning multiple large files can take time, consider async with progress
- **Error handling**: Some files may fail (permissions, corruption), show which succeeded/failed
- **Real-time updates**: Use LiveView to update UI as files are scanned
- **FFprobe availability**: Detect and warn if FFprobe is not installed
- **Rate limiting**: Prevent spam-clicking the refresh button

## Files to Modify
- `lib/mydia_web/live/media_live/show.ex` - Add handle_event for refresh
- `lib/mydia_web/live/media_live/show.html.heex` - Add refresh button UI
- Consider: Add to TV show episode detail pages as well

## UX Flow
1. User clicks "Refresh Metadata" button on movie/show page
2. Button shows loading spinner
3. System re-scans all media files for that item
4. Toast notification shows success/failure
5. Media file cards update with new metadata
6. Button returns to normal state

## Related
- Builds on task-76 (file metadata extraction implementation)
- Complements task-75 (media files card layout)
- Could be extended to automatic re-scanning on file modification detection
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Refresh button visible on movie detail page media files section
- [x] #2 Refresh button visible on TV show detail page media files section
- [x] #3 Button triggers metadata re-scan for all files of the media item
- [x] #4 Loading state shown while scanning is in progress
- [x] #5 Success toast message shown after successful refresh
- [x] #6 Error toast message shown if refresh fails
- [x] #7 Media file display updates with new metadata after refresh
- [x] #8 Button is disabled during scanning to prevent duplicate requests
- [x] #9 Tooltip or help text explains what the button does
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully implemented a re-scan metadata button for movies and TV shows on the media detail page.

### Changes Made

1. **Template Updates** (`lib/mydia_web/live/media_live/show.html.heex`):
   - Added "Refresh Metadata" button in the media files card header (line 407-419)
   - Button shows loading spinner when refreshing is in progress
   - Button is disabled during the refresh operation
   - Uses hero-arrow-path icon for consistency

2. **LiveView Updates** (`lib/mydia_web/live/media_live/show.ex`):
   - Added `@refreshing_file_metadata` state tracking in mount (line 62)
   - Implemented `handle_event("refresh_all_file_metadata", ...)` handler (line 212-225)
   - Added async handlers for the refresh operation (lines 891-922)
   - Created `refresh_files/1` helper function (lines 1484-1503)

3. **Functionality**:
   - Uses `Library.refresh_file_metadata/1` for each media file
   - Runs the refresh asynchronously using `start_async` to prevent blocking the UI
   - Tracks success and error counts
   - Reloads the media item after completion to show updated metadata
   - Shows appropriate toast messages with counts

### Technical Details

- **Async Processing**: Uses LiveView's async operations to avoid blocking the UI during file scanning
- **Error Handling**: Gracefully handles errors and provides feedback to the user
- **Real-time Updates**: Media file display updates immediately after refresh completes
- **Loading States**: Button shows loading spinner and is disabled during operation

### User Experience

1. User clicks "Refresh Metadata" button on media detail page
2. Button shows loading spinner and is disabled
3. System re-scans all media files using FFprobe and filename parsing
4. Toast notification shows success with count (e.g., "Successfully refreshed 3 file(s)")
5. Media file cards update with new metadata (resolution, codec, audio)
6. If errors occur, shows count of failures

### Notes

- The implementation works for both movies and TV shows
- All media files for the item are refreshed when the button is clicked
- The refresh uses the existing `Library.refresh_file_metadata/1` function which combines FFprobe analysis with filename parsing
- Future enhancement could add per-file refresh buttons, but the current implementation handles the common use case efficiently
<!-- SECTION:NOTES:END -->
