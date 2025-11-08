---
id: task-79
title: Add start/pause buttons to downloads queue
status: Done
assignee: []
created_date: '2025-11-05 18:23'
updated_date: '2025-11-05 18:27'
labels:
  - enhancement
  - downloads
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add individual start/pause controls for downloads in the queue to allow users to manually control download progress without having to cancel or delete them.

Currently, users can only cancel/delete downloads from the queue. However, many download clients support pausing and resuming torrents, which would be useful for:
- Temporarily pausing downloads to free up bandwidth
- Prioritizing certain downloads over others
- Managing seeding behavior after completion

The download client adapters (Transmission, qBittorrent) should already support these operations through their APIs. We need to:
1. Add pause/resume methods to the download client behavior and adapters
2. Add pause/resume buttons to the downloads queue UI (replacing or alongside cancel button)
3. Update the UI to show the current state (paused vs active) more clearly
4. Handle edge cases where pause/resume operations fail

This should work with the existing real-time download status system that fetches torrent state from clients.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Downloads queue shows pause button for active downloads (downloading, seeding)
- [x] #2 Downloads queue shows resume/start button for paused downloads
- [x] #3 Pause action successfully pauses the torrent in the download client
- [x] #4 Resume action successfully resumes the torrent in the download client
- [x] #5 UI updates in real-time to reflect paused/resumed state
- [x] #6 Error handling for failed pause/resume operations with user feedback
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully added pause/resume functionality to the downloads queue. The feature leverages the existing pause/resume methods in the download client adapters (Transmission and qBittorrent).

### Changes Made:

1. **Downloads Context** (lib/mydia/downloads.ex)
   - Added `pause_download/1` function - pauses a download in the client and broadcasts update
   - Added `resume_download/1` function - resumes a paused download in the client and broadcasts update
   - Both functions follow the same pattern as `cancel_download/2` with proper error handling and logging

2. **Downloads LiveView** (lib/mydia_web/live/downloads_live/index.ex)
   - Added `handle_event("pause_download", ...)` - handles pause button clicks
   - Added `handle_event("resume_download", ...)` - handles resume button clicks
   - Both handlers provide user feedback via flash messages and reload downloads

3. **Downloads UI Template** (lib/mydia_web/live/downloads_live/index.html.heex)
   - Updated action buttons in the queue tab to show:
     - Play button (hero-play icon) for paused downloads - triggers resume
     - Pause button (hero-pause icon) for active downloads - triggers pause
     - Cancel button (hero-x-mark icon) remains for all downloads
   - Buttons are properly styled and have tooltips for accessibility

### How It Works:

- The UI dynamically shows pause or resume button based on `download.status`
- When paused, downloads show status badge as "Paused" with warning color
- Real-time updates work automatically through existing PubSub broadcast system
- Error handling provides user-friendly messages if operations fail in the client

### Technical Notes:

- Client adapters (Transmission/qBittorrent) already had pause/resume methods implementing the Client behavior
- The pause/resume operations are stateless - the download client maintains the torrent state
- Database records remain unchanged; only client state is modified
- UI updates happen in real-time through the existing download monitoring system
<!-- SECTION:NOTES:END -->
