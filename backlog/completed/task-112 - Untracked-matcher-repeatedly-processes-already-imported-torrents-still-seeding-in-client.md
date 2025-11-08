---
id: task-112
title: >-
  Untracked matcher repeatedly processes already-imported torrents still seeding
  in client
status: Done
assignee: []
created_date: '2025-11-06 18:54'
updated_date: '2025-11-06 19:09'
labels:
  - bug
  - downloads
  - untracked-matcher
  - performance
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The untracked torrent matcher repeatedly attempts to match torrents that were added by Mydia, successfully imported, and are now seeding in the download client. This happens because:

1. Mydia adds torrent and creates download record
2. Download completes and MediaImport job runs
3. Import succeeds and creates media_file records
4. Download record is deleted (downloads table is ephemeral)
5. Torrent remains in client (seeding)
6. DownloadMonitor's UntrackedMatcher sees it as "untracked" (no download record)
7. Attempts to match it every monitoring cycle

**Current Behavior:**
Logs show repeated processing of the same torrents:
```
[debug] Processing untracked torrent: www.UIndex.org - The Matrix 1999 1080p Bluray OPUS 7 1 AV1-WhiskeyJack
[debug] No library match found for torrent: www.UIndex.org - The Matrix 1999 1080p Bluray OPUS 7 1 AV1-WhiskeyJack
```

This torrent was added by Mydia and imported 15+ hours ago, but is still being processed as "untracked" on every monitoring cycle.

**Root Cause:**
`UntrackedMatcher.find_and_match_untracked` (line 32 in `lib/mydia/downloads/untracked_matcher.ex`) only checks if a torrent has a download record, not if its content has already been imported to the library.

**Impact:**
- Wasted processing on every monitoring cycle
- Confusing debug logs suggesting external additions
- Potential for duplicate download records if matching succeeds

**Solution Options:**
1. **Enhanced cleanup:** Ensure torrents are removed from client after import completes
2. **Smart matching:** Before attempting to match, check if torrent's files already exist in library based on filename/path matching
3. **Tracking flag:** Mark torrents as "imported" in client tags/labels to skip them
4. **Import history:** Keep lightweight record of imported torrent client IDs to skip them
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Untracked matcher skips torrents whose content is already in library
- [x] #2 No repeated processing of same torrent across monitoring cycles
- [x] #3 Clear distinction in logs between truly untracked vs already-imported torrents
- [x] #4 Consider whether to keep torrents for seeding vs remove after import
- [x] #5 Document expected behavior for post-import torrent management
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Solution Implemented

The fix prevents the untracked matcher from repeatedly processing torrents that have already been imported to the library by:

1. **Storing client identifiers in media_file metadata** (lib/mydia/jobs/media_import.ex:595-596):
   - Added `download_client` and `download_client_id` to the media_file metadata during import
   - This creates a permanent record linking imported files to their source torrent

2. **Adding library lookup function** (lib/mydia/library.ex:282-290):
   - Created `Library.torrent_already_imported?/2` to check if a torrent has been imported
   - Uses SQL JSON extraction to query media_files by client name and client ID
   - Returns true if any media_file has the matching client identifiers

3. **Filtering already-imported torrents** (lib/mydia/downloads/untracked_matcher.ex:49-126):
   - Added `filter_already_imported_torrents/1` function to skip imported torrents
   - Integrated into the untracked matching flow after finding untracked torrents
   - Logs clear debug messages distinguishing already-imported vs truly untracked torrents

## Behavior Changes

**Before:**
- Torrents that completed and were imported would be re-processed on every monitoring cycle
- Logs showed repeated "Processing untracked torrent" and "No library match found" messages for seeding torrents

**After:**
- Torrents that have been imported are identified and skipped
- Logs show "Skipping already-imported torrent" (debug level) for these torrents
- Info log shows count breakdown: "X torrent(s) not yet imported (Y already in library)"
- Only truly untracked/external torrents are processed

## Post-Import Torrent Management

The implementation allows torrents to remain in the client for seeding after import, which is the desired behavior for maintaining ratio. Torrents are automatically removed from the client after import based on the `cleanup_client` setting in the MediaImport job (defaults to true), but this can be configured per-import.
<!-- SECTION:NOTES:END -->
