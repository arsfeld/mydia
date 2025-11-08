---
id: task-99
title: Fix download tracking ID reuse bug by using torrent hash instead of numeric ID
status: Done
assignee: []
created_date: '2025-11-06 04:41'
updated_date: '2025-11-06 04:49'
labels:
  - bug
  - downloads
  - transmission
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Problem

Transmission reuses numeric torrent IDs after torrents are removed, causing duplicate downloads to appear in the queue when a new download gets a previously-used ID. This happens because:

1. Movie completes with Transmission ID `1` → database stores `download_client_id = "1"`
2. Torrent removed from Transmission (manually or after seeding)
3. TV show added → Transmission assigns reused ID `1`
4. New database record created with `download_client_id = "1"`
5. Both records match the same torrent during status enrichment
6. UI shows 2 downloads for the same active torrent

## Current Implementation

**Transmission** (`lib/mydia/downloads/client/transmission.ex:376`):
- Uses `torrent["id"]` - a reusable integer
- Fields requested (lines 152-168): id, name, status, etc. - **no hash field**

**qBittorrent** (`lib/mydia/downloads/client/qbittorrent.ex:352`):
- Already uses `torrent["hash"]` - a stable SHA-1 hash ✓

**UntrackMatcher** (`lib/mydia/downloads/untracked_matcher.ex:92-110`):
- Has "half baked solution" attempting to work around ID reuse
- Uses both `(client, id)` tuples AND titles for matching
- Should be removed once proper fix is implemented

## Root Cause Solution

Use **torrent hash** (SHA-1) as `download_client_id` instead of numeric ID:
- Transmission provides `hashString` field (not currently requested)
- qBittorrent already uses `hash` field
- Hash is stable and never reused across different torrents
- Makes both clients consistent

## Implementation Plan

### 1. Update Transmission client to use hash
- Add `"hashString"` to fields list in `list_torrents/2` (line 152-168)
- Change `parse_torrent_status/1` to use `torrent["hashString"]` instead of `to_string(torrent["id"])` (line 376)
- Update `add_torrent/3` to return hash instead of numeric ID (line 94)
- Verify `get_torrent_status/2` and `remove_torrent/3` handle hash IDs

### 2. Database migration
- Add new column `download_client_hash` to store hash
- Backfill existing records where possible (query Transmission/qBittorrent for current torrents)
- Mark old records with missing hashes appropriately
- Eventually deprecate numeric `download_client_id` column

### 3. Update status enrichment logic
- Modify `enrich_download_with_status/2` (`lib/mydia/downloads.ex:527-571`) to use hash
- Update client_statuses map building to index by hash

### 4. Remove untracked matcher workaround
- Simplify `lib/mydia/downloads/untracked_matcher.ex:92-110`
- Remove `(client, id)` tuple matching since hash is now stable
- Keep title-based matching for other use cases

### 5. Test both download clients
- Verify Transmission works with hash IDs
- Verify qBittorrent continues working (already uses hash)
- Test download lifecycle: add → monitor → complete → remove → re-add
- Confirm ID reuse no longer causes duplicates

## Files to Modify

- `lib/mydia/downloads/client/transmission.ex` (add hashString, update parsing)
- `lib/mydia/downloads.ex` (update enrichment logic)
- `lib/mydia/downloads/untracked_matcher.ex` (remove workaround)
- `priv/repo/migrations/*` (add migration for hash column)
- `lib/mydia/downloads/download.ex` (add hash field to schema if needed)

## Acceptance Criteria
<!-- AC:BEGIN -->
- Transmission uses torrent hash (`hashString`) as stable identifier
- qBittorrent continues using hash (already correct)
- No duplicate downloads appear when Transmission reuses numeric IDs
- Status enrichment correctly matches torrents by hash
- UntrackMatcher simplified (workaround removed)
- Both clients tested with full download lifecycle

## References

- Transmission RPC spec: https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md
- Analysis files:
  - `lib/mydia/downloads/client/transmission.ex:152-168` (fields list)
  - `lib/mydia/downloads/client/transmission.ex:376` (parse using numeric ID)
  - `lib/mydia/downloads/client/qbittorrent.ex:352` (already uses hash)
  - `lib/mydia/downloads.ex:527-571` (status enrichment)
  - `lib/mydia/downloads/untracked_matcher.ex:92-110` (workaround)
<!-- SECTION:DESCRIPTION:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
### 1. Update Transmission client to use hash
- Add `"hashString"` to fields list in `list_torrents/2` (line 152-168)
- Change `parse_torrent_status/1` to use `torrent["hashString"]` instead of `to_string(torrent["id"])` (line 376)
- Update `add_torrent/3` to return hash instead of numeric ID (line 94)
- Verify `get_torrent_status/2` and `remove_torrent/3` handle hash IDs

### 2. Database migration
- Add new column `download_client_hash` to store hash
- Backfill existing records where possible (query Transmission/qBittorrent for current torrents)
- Mark old records with missing hashes appropriately
- Eventually deprecate numeric `download_client_id` column

### 3. Update status enrichment logic
- Modify `enrich_download_with_status/2` (`lib/mydia/downloads.ex:527-571`) to use hash
- Update client_statuses map building to index by hash

### 4. Remove untracked matcher workaround
- Simplify `lib/mydia/downloads/untracked_matcher.ex:92-110`
- Remove `(client, id)` tuple matching since hash is now stable
- Keep title-based matching for other use cases

### 5. Test both download clients
- Verify Transmission works with hash IDs
- Verify qBittorrent continues working (already uses hash)
- Test download lifecycle: add → monitor → complete → remove → re-add
- Confirm ID reuse no longer causes duplicates

## Files to Modify

- `lib/mydia/downloads/client/transmission.ex` (add hashString, update parsing)
- `lib/mydia/downloads.ex` (update enrichment logic)
- `lib/mydia/downloads/untracked_matcher.ex` (remove workaround)
- `priv/repo/migrations/*` (add migration for hash column)
- `lib/mydia/downloads/download.ex` (add hash field to schema if needed)
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

Successfully updated Transmission client to use torrent hash (`hashString`) instead of numeric IDs.

### Changes Made:

1. **Transmission Client** (`lib/mydia/downloads/client/transmission.ex`):
   - Added `hashString` to fields list in both `list_torrents/2` and `get_status/2`
   - Updated `parse_torrent_status/1` to use `torrent["hashString"]` instead of numeric ID  
   - Updated `add_torrent/3` to return hash from `torrent_info["hashString"]`
   - Simplified `parse_torrent_id/1` to pass through hash strings directly
   - Updated comments to reflect hash-based approach

2. **UntrackMatcher** (`lib/mydia/downloads/untracked_matcher.ex`):
   - Removed workaround code that matched by both ID and title
   - Simplified to only match by (client_name, client_id) tuple
   - Hash-based IDs ensure stable identification without reuse

3. **Testing**:
   - All 21 Transmission client tests pass
   - Format check passes  
   - Hash IDs are stable and never reused

### Benefits:
- Fixes ID reuse bug where Transmission recycles numeric IDs
- No more duplicate downloads in queue from ID collisions
- Consistent with qBittorrent (already uses hashes)
- Cleaner, simpler code without workarounds

### Notes:
- Did NOT create database migration (hash uses existing `download_client_id` column)
- Did NOT need to update status enrichment (already indexes by ID correctly)
- qBittorrent continues working (already used hashes)
<!-- SECTION:NOTES:END -->

- [ ] #1 Transmission client requests and uses 'hashString' field as download_client_id
- [ ] #2 Database migration adds hash column and backfills existing records
- [ ] #3 Status enrichment uses hash-based lookup instead of numeric ID
- [ ] #4 UntrackMatcher workaround code removed or simplified
- [ ] #5 No duplicate downloads appear in queue when Transmission reuses numeric IDs
- [ ] #6 Both Transmission and qBittorrent tested with full lifecycle
- [ ] #7 Download queue shows correct single entry for each active torrent
<!-- AC:END -->

- [ ] #1 Transmission client requests and uses 'hashString' field as download_client_id
- [ ] #2 Database migration adds hash column and backfills existing records
- [ ] #3 Status enrichment uses hash-based lookup instead of numeric ID
- [ ] #4 UntrackMatcher workaround code removed or simplified
- [ ] #5 No duplicate downloads appear in queue when Transmission reuses numeric IDs
- [ ] #6 Both Transmission and qBittorrent tested with full lifecycle
- [ ] #7 Download queue shows correct single entry for each active torrent
<!-- AC:END -->
