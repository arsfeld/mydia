---
id: task-110
title: >-
  Fix duplicate download prevention to check media_files not just active
  downloads
status: Done
assignee: []
created_date: '2025-11-06 18:52'
updated_date: '2025-11-06 19:07'
labels:
  - bug
  - downloads
  - duplicate-prevention
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The duplicate detection in `Downloads.check_for_duplicate_download/2` only checks for active downloads in the ephemeral `downloads` table. Once a download completes and the record is deleted, there's nothing preventing the background search from re-downloading the same content.

**Root Cause:** Line 329 in `lib/mydia/downloads.ex`:
```elixir
base_query =
  Download
  |> where([d], is_nil(d.completed_at) and is_nil(d.error_message))
```

This only checks for active downloads. Since the downloads table is ephemeral (records are deleted after completion/failure), completed downloads are not tracked.

**Impact:**
- Background search re-downloads movies/episodes that already have media_files
- Wastes bandwidth and storage
- Causes confusion (e.g., "The Matrix" was downloaded again 15 hours after being imported)

**Solution:**
Enhance `check_for_duplicate_download` to also check if media_files already exist for the target media_item or episode before initiating a download.

**Related:**
- task-108 (historical download tracking with events system)
- This is separate from the unique constraint fix which only prevents duplicate download records
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Add check in check_for_duplicate_download to query media_files table for existing files
- [x] #2 For movies: check if media_files exist for the media_item_id
- [x] #3 For episodes: check if media_files exist for the episode_id
- [x] #4 For season packs: check if any episodes in the season already have media_files
- [x] #5 Return :duplicate_download error if media_files exist, preventing re-download
- [x] #6 Test that background search doesn't re-download content that already has files
<!-- AC:END -->
