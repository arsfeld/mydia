---
id: task-29
title: Implement download initiation from search results UI
status: Done
assignee: []
created_date: '2025-11-04 16:00'
updated_date: '2025-11-06 01:04'
labels:
  - downloads
  - liveview
  - ui
  - search
dependencies:
  - task-22.8
  - task-21.1
  - task-21.2
  - task-21.4
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Complete the stubbed download functionality in the search LiveView. When a user clicks the download button for a search result, send the torrent to a configured download client and create a Download record to track progress.

This enables the core acquisition workflow: user searches for media → finds a release → downloads it directly. The download can be associated with a media item (if searching from library) or standalone (if from discovery search).

## Implementation Details

The download button handler exists at `lib/mydia_web/live/search_live/index.ex:99-105` with a TODO placeholder. This task implements the actual functionality.

**Download Flow:**
1. User clicks download button on search result
2. If multiple download clients configured, prompt user to select one (or use default/priority)
3. Send magnet link or torrent file URL to selected download client
4. Create Download record with initial status
5. Show success flash message with link to downloads queue
6. Download monitoring job (task-21.4) handles status updates

**Error Handling:**
- Download client unavailable/offline
- Torrent rejected by client
- Invalid magnet link or torrent file
- No download clients configured

**Context Module:**
Use existing `Mydia.Downloads` context and download client adapters from task-21.1/21.2.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Download button in search results sends torrent to download client
- [x] #2 Creates Download record with pending status and metadata
- [x] #3 Handles multiple configured download clients (selection or priority)
- [x] #4 Shows success message with link to downloads queue
- [x] #5 Handles errors gracefully (client offline, invalid torrent, etc.)
- [x] #6 Download appears in downloads queue UI immediately
- [x] #7 Download monitoring job picks up and tracks status
- [x] #8 Can optionally associate download with media_item_id if known
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Review (2025-11-05)

Current status: STUBBED BUT NOT IMPLEMENTED

**What exists:**
- UI handles "add to library" with optional download flag
- Assigns stored: pending_download_url, should_download_after_add
- handle_info(:trigger_download) exists at search_live/index.ex:282-287

**What's missing:**
- The :trigger_download handler only logs, doesn't actually initiate downloads
- Comment says: "Currently just logs, but will integrate with actual download functionality"
- No call to Downloads.create_download/1 or similar
- No download client selection logic
- No error handling for download failures

**To implement:**
1. Add Downloads context call in handle_info(:trigger_download)
2. Implement download client selection/priority logic
3. Add error handling and user feedback
4. Associate download with media_item_id if known
5. Show success message with link to downloads queue

This task is properly scoped and ready to be worked on.
<!-- SECTION:NOTES:END -->
