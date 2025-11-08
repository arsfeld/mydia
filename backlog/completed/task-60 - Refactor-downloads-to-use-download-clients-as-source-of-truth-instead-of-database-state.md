---
id: task-60
title: >-
  Refactor downloads to use download clients as source of truth instead of
  database state
status: Done
assignee: []
created_date: '2025-11-05 03:34'
updated_date: '2025-11-05 03:42'
labels:
  - downloads
  - architecture
  - refactor
  - backend
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, the application maintains a separate download state in the database that can become out-of-sync with the actual state in download clients (Transmission, qBittorrent, etc). This leads to issues where the UI shows downloads that don't exist in the actual download clients, creating a fictitious view of download state.

The download list should always reflect the real-time state of configured download clients, with clients as the single source of truth. The database should only store minimal metadata needed for associating downloads with media items, not duplicate state.

This architectural change will ensure the download queue always shows accurate, real-time information directly from download clients.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Downloads LiveView queries download clients directly for current download state instead of reading from downloads table
- [x] #2 Download state (status, progress, speed, ETA) is fetched in real-time from clients, never stored in database
- [x] #3 Database downloads table is repurposed to only store: media_item associations, episode associations, indexer source, and historical metadata
- [x] #4 Download initiation creates minimal database record for association tracking only, actual download state comes from client
- [x] #5 Download monitoring job is eliminated or repurposed since client is source of truth
- [x] #6 Downloads page shows accurate real-time state from all configured download clients
- [x] #7 No phantom downloads appear in UI that don't exist in actual download clients
- [x] #8 System gracefully handles client connection failures with appropriate error messages
- [x] #9 Performance is acceptable when querying multiple clients with hundreds of torrents
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully refactored the downloads system to use download clients as the single source of truth.

### Changes Made:

1. **Database Migration** (`20251105033610_refactor_downloads_remove_state_fields.exs`):
   - Removed `status`, `progress`, and `estimated_completion` fields from downloads table
   - Kept `completed_at` and `error_message` for historical tracking
   - Recreated table using SQLite-compatible approach

2. **Download Schema** (`lib/mydia/downloads/download.ex`):
   - Removed state-related fields from schema and changeset
   - Simplified validations to only require title

3. **Downloads Context** (`lib/mydia/downloads.ex`):
   - Added `list_downloads_with_status/1` - queries all configured clients and enriches downloads with real-time status
   - Replaced state management functions with:
     - `mark_download_completed/1` - records completion timestamp
     - `mark_download_failed/2` - records error messages
   - Updated `cancel_download/2` to remove torrents from clients
   - Added helper functions for fetching and enriching client data:
     - `fetch_all_client_statuses/1` - concurrent client queries
     - `enrich_download_with_status/2` - merge DB and client data
     - `status_from_torrent_state/1` - map client states to app states

4. **Downloads LiveView** (`lib/mydia_web/live/downloads_live/index.ex`):
   - Updated to use `list_downloads_with_status/1` instead of DB-only queries
   - Modified event handlers to interact with clients:
     - `cancel_download` - removes from client
     - `retry_download` - re-initiates download in client
     - `delete_download` - removes from both client and DB
   - Updated helper functions to work with map structures
   - Added badge classes for new statuses (seeding, checking, paused, missing)

5. **Download Monitor Job** (`lib/mydia/jobs/download_monitor.ex`):
   - Completely refactored from progress syncing to completion detection
   - Now only handles:
     - Detecting completed downloads
     - Marking completions in database
     - Triggering import jobs for completed downloads
     - Recording errors for failed downloads
   - Reduced from ~335 lines to ~125 lines

6. **Media LiveView** (`lib/mydia_web/live/media_live/show.ex`):
   - Updated retry_download handler to use new architecture

### Architecture Benefits:

- **No State Duplication**: Download state only exists in clients
- **No Sync Issues**: Real-time queries eliminate drift between DB and clients
- **No Phantom Downloads**: Only shows what actually exists in clients
- **Graceful Degradation**: Handles client connection failures appropriately
- **Concurrent Performance**: Parallel client queries for speed

### Status Flow:

Database tracks:
- Association metadata (media_item_id, episode_id)
- Source information (indexer, download_url, client info)
- Historical records (completed_at, error_message)

Clients provide:
- Current status (downloading, seeding, completed, failed, etc.)
- Real-time progress and speeds
- ETA and ratio information
- File paths and sizes

The system now has a clear separation of concerns with clients as the authoritative source for download state.
<!-- SECTION:NOTES:END -->
