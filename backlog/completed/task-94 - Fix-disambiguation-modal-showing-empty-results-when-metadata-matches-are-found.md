---
id: task-94
title: Fix disambiguation modal showing empty results when metadata matches are found
status: Done
assignee: []
created_date: '2025-11-06 03:09'
updated_date: '2025-11-06 03:22'
labels:
  - bug
  - ui
  - metadata
  - search
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When adding an item from the search page, the system correctly finds metadata matches (e.g., "Found 6 metadata matches") and triggers the disambiguation modal, but the modal displays empty spaces instead of showing the actual match options to the user.

**Reproduction:**
1. Search for a release (e.g., "Bluey 2018 S02E15")
2. Click "Add to Library"
3. System logs show "Found 6 metadata matches, requires disambiguation"
4. Disambiguation modal appears but shows 6 empty spaces with no match details
5. User cannot select a match because nothing is displayed

**Technical context:**
- File parser successfully parses the release
- Metadata provider search returns matches
- Modal is triggered correctly
- Issue appears to be in the modal's display logic or data binding

**Log excerpt:**
```
[info] Found 6 metadata matches, requires disambiguation
[info] Multiple metadata matches found, showing disambiguation modal
```

The modal UI is not properly rendering the metadata results even though they exist.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 When metadata search returns multiple matches, all matches are displayed in the disambiguation modal with their titles and relevant details
- [x] #2 User can view and select from the displayed metadata options
- [x] #3 Modal correctly binds to and displays the metadata results passed to it
- [x] #4 Test with various types of media (TV shows, movies) to ensure consistent display
- [x] #5 No console errors or warnings related to the modal rendering
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Root Cause

The disambiguation modal was displaying empty spaces because of a **data structure mismatch** between the backend and frontend:

1. **Metadata search results** are returned as maps with **atom keys** (`:provider_id`, `:title`, `:poster_path`, `:overview`, etc.) from `lib/mydia/metadata/provider/relay.ex`

2. **The template** was trying to access these maps using **string keys** (`match["id"]`, `match["title"]`, etc.)

3. Since string keys don't exist on atom-keyed maps in Elixir, all property accesses returned `nil`, causing the modal to display empty spaces

## Changes Made

### 1. Updated Metadata Provider (`lib/mydia/metadata/provider/relay.ex`)
- Added `release_date` and `first_air_date` fields to `parse_search_result/1` function
- These fields are now preserved from the API response for display in the UI

### 2. Updated LiveView Event Handlers (`lib/mydia_web/live/search_live/index.ex`)
- Fixed `handle_event("select_metadata_match")` to use `m.provider_id` instead of `m["id"]`
- Fixed `handle_event("select_manual_match")` to use `m.provider_id` instead of `m["id"]`
- Updated `fetch_full_metadata/3` to use `match.provider_id` instead of `match["id"] || match["provider_id"]`
- **Fixed `create_media_item_from_metadata/2`** to use `metadata.provider_id` instead of `metadata["id"]`
- **Fixed `build_media_item_attrs/2`** to use atom keys for all metadata access
- **Fixed `build_media_item_attrs_from_metadata_only/2`** to use atom keys for all metadata access
- **Enhanced `extract_year_from_date/1`** to handle both Date structs and strings
- **Fixed boolean operator** from `and` to `&&` in conditional check for season and episodes (line 826)

### 3. Updated Templates (`lib/mydia_web/live/search_live/index.html.heex`)
- **Disambiguation modal**: Changed all `match["field"]` to `match.field` (atom key access)
- **Manual search modal**: Changed all `match["field"]` to `match.field`
- Updated media type checks to use atom comparison (`:tv_show` instead of `"tv"`)
- Changed `match["id"]` to `match.provider_id` in `phx-value-match_id` attributes

## Bugs Fixed

### Bug #1: Empty Modal Display
The template was using string keys to access atom-keyed maps, causing all fields to return `nil`.

### Bug #2: TMDB ID Comparison Error
```
comparing `m.tmdb_id` with `nil` is forbidden as it is unsafe
```
Fixed by updating all metadata field accesses to use atom keys consistently.

### Bug #3: Boolean Operator Error
```
{:badbool, :and, 2}
```
The code used `parsed.season and parsed.episodes` but `and` requires boolean operands. Since `parsed.season` is an integer (e.g., `2`), this failed. Changed to `&&` which handles truthy/falsy values correctly.

## Testing
- Code compiles successfully without errors
- Both disambiguation and manual search modals now use consistent atom key access
- All metadata fields (title, poster, overview, release date) are properly preserved and accessible
- Full metadata flow from search → disambiguation → creation works correctly
- TV show episodes are created properly when season/episode info is present
<!-- SECTION:NOTES:END -->
