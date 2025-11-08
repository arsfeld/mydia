---
id: task-71
title: Remove downloading status from items not detected in any download tracker
status: Done
assignee: []
created_date: '2025-11-05 14:51'
updated_date: '2025-11-05 14:57'
labels:
  - bug
  - downloads
  - data-sync
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, when a download is added to the system and then manually removed from the download client (e.g., Transmission), the media item remains stuck with a "downloading" status indefinitely. This creates an inconsistent state between the download tracker and the database.

The system needs a mechanism to detect downloads that no longer exist in any configured download client and update their status accordingly.

**Current Behavior:**
1. User adds a download (movie/episode) which creates a Download record
2. Download appears in the download client (Transmission)
3. User manually removes the download from Transmission
4. Media item in Mydia still shows as "downloading" forever

**Expected Behavior:**
The system should periodically check if downloads marked as active still exist in the download client, and update the status if they've been removed externally.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Downloads that no longer exist in any tracker are detected and updated
- [x] #2 Status is cleared/updated appropriately when download is not found
- [x] #3 Sync happens automatically (via existing DownloadMonitor job or similar)
- [x] #4 Manual trigger option available for immediate sync
- [x] #5 Handles edge cases like tracker being temporarily unavailable
<!-- AC:END -->
