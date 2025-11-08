---
id: task-43.6
title: Add download management actions to details page
status: Done
assignee:
  - assistant
created_date: '2025-11-04 21:11'
updated_date: '2025-11-04 21:30'
labels:
  - feature
  - ui
  - downloads
dependencies:
  - task-21
parent_task_id: task-43
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement actions for managing downloads from the media details page.

- Retry failed downloads
- Cancel active/pending downloads
- Remove completed downloads from history
- View detailed download information (torrent info, peers, speed, etc.)
- Priority adjustment for queued downloads
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 User can retry failed downloads
- [x] #2 User can cancel active downloads
- [x] #3 Download details are accessible
- [x] #4 Actions update the download status appropriately
- [x] #5 UI reflects changes in real-time via PubSub
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Add retry_download/1 to Downloads Context
- Reset status to "pending"
- Clear error_message
- Reset progress to 0
- Broadcast update via PubSub

### 2. Add Actions Column to Downloads Table
- Show context-appropriate actions based on status:
  - Failed: Retry, Delete
  - Pending/Downloading: Cancel, View Details
  - Completed/Cancelled: Delete, View Details

### 3. Implement Event Handlers in show.ex
- `handle_event("retry_download", ...)` - Retry failed download
- `handle_event("cancel_download", ...)` - Cancel active download
- `handle_event("delete_download_record", ...)` - Remove from history
- `handle_event("show_download_details", ...)` - Open details modal

### 4. Add UI Modals
- Cancel confirmation modal
- Delete confirmation modal  
- Download details modal showing torrent info, metadata, error messages

### 5. Real-time Updates
- Already handled via existing PubSub subscription
- Show flash messages for user actions

## Key Files
- lib/mydia/downloads.ex
- lib/mydia_web/live/media_live/show.ex
- lib/mydia_web/live/media_live/show.html.heex
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented all download management features:
- Added retry_download/1 function to Downloads context
- Added context-aware actions dropdown (retry for failed, cancel for active, delete for all)
- Created cancel confirmation modal
- Created delete confirmation modal
- Created detailed download details modal showing status, progress, source URL, error messages, timestamps, and metadata
- All operations broadcast via PubSub for real-time UI updates
- Flash messages provide user feedback for all operations
<!-- SECTION:NOTES:END -->
