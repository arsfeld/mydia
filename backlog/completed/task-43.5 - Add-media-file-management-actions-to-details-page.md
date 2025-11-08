---
id: task-43.5
title: Add media file management actions to details page
status: Done
assignee:
  - assistant
created_date: '2025-11-04 21:11'
updated_date: '2025-11-04 21:30'
labels:
  - feature
  - ui
  - media-files
dependencies: []
parent_task_id: task-43
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement actions for managing individual media files on the details page.

- Delete file (with confirmation)
- Mark as primary/preferred version
- Reacquire/replace file
- View full file details (metadata, codecs, bitrate, etc.)
- File verification status
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 User can delete individual media files
- [x] #2 User can mark preferred version
- [x] #3 File details are accessible
- [x] #4 Actions have appropriate confirmations
- [x] #5 Changes are reflected immediately in the UI
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Add Actions Column to Media Files Table
- Add action buttons (delete, view details, mark preferred)
- Use dropdown menu for compact layout

### 2. Implement Event Handlers in show.ex
- `handle_event("delete_media_file", ...)` - Delete with confirmation
- `handle_event("show_file_details", ...)` - Open details modal
- `handle_event("mark_file_preferred", ...)` - Update quality_profile_id on the file

### 3. Add UI Modals
- Delete confirmation modal
- File details modal showing full metadata (codec, bitrate, audio, HDR, etc.)

### 4. Real-time Updates
- Reload media item after any file operation
- Show flash messages for success/error feedback

## Key Files
- lib/mydia_web/live/media_live/show.ex
- lib/mydia_web/live/media_live/show.html.heex
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented all media file management features:
- Added actions dropdown with delete, view details, and mark preferred options
- Created delete confirmation modal with file information display
- Created detailed file details modal showing path, quality, codecs, HDR, bitrate, and verification status
- All actions reload the media item to reflect changes immediately
- Flash messages provide user feedback for all operations
<!-- SECTION:NOTES:END -->
