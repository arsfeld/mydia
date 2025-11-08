---
id: task-116.3
title: Add alternative/AKA title support from TMDB metadata
status: Done
assignee: []
created_date: '2025-11-08 02:18'
updated_date: '2025-11-08 03:14'
labels: []
dependencies: []
parent_task_id: task-116
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Support matching releases that use alternative titles, localized names, or AKA titles from TMDB.

**Problem**: Movies often have different titles in different regions or multiple official names. Releases may use any of these variants.

**Examples**:
- "Edge of Tomorrow" / "Live Die Repeat"
- "The Matrix" / "黑客帝国" (Chinese title)
- "Leon: The Professional" / "The Professional" / "Leon"

**Implementation**:
1. Fetch alternative titles from TMDB when importing movies
2. Store alternative titles in movie metadata
3. Update TorrentMatcher to check against all title variants
4. Prioritize primary title matches over alternative titles

**Files to modify**:
- `lib/mydia/metadata/provider/tmdb.ex` - Fetch alternative titles
- Database migration to add alternative_titles field
- `lib/mydia/downloads/torrent_matcher.ex` - Check all title variants
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Alternative titles are fetched from TMDB during movie import
- [ ] #2 Database stores alternative titles as JSON array
- [ ] #3 Matcher checks both primary and alternative titles
- [ ] #4 Primary title matches score higher than alternative title matches
- [ ] #5 Tests include movies with known alternative titles
- [ ] #6 Migration handles existing movies without breaking data
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete (2025-11-08)

**Changes made:**
1. Updated metadata relay provider to fetch alternative titles from TMDB API
2. Added `parse_alternative_titles` function to extract titles from TMDB response
3. Updated Provider metadata typespec to include `alternative_titles` field
4. Modified TorrentMatcher to check against all title variants (primary, original, alternative)
5. Added `get_title_variants` helper function to extract all title options
6. Implemented -0.05 confidence penalty for alternative title matches to prefer primary titles
7. Added comprehensive test suite with 10 tests covering all scenarios

**Test results:**
- All 10 new tests passing
- All 53 existing torrent matcher tests still passing
- No regressions introduced

**Files modified:**
- `lib/mydia/metadata/provider/relay.ex` - Fetch and parse alternative titles
- `lib/mydia/metadata/provider.ex` - Updated typespec and documentation
- `lib/mydia/downloads/torrent_matcher.ex` - Check alternative titles in matching
- `test/mydia/downloads/torrent_matcher_alternative_titles_test.exs` - New test file

**Acceptance criteria met:**
- [x] Alternative titles are fetched from TMDB during movie import
- [x] Database stores alternative titles as JSON array (in metadata field)
- [x] Matcher checks both primary and alternative titles
- [x] Primary title matches score higher than alternative title matches (-0.05 penalty)
- [x] Tests include movies with known alternative titles
- [x] Migration handles existing movies without breaking data (no migration needed, uses existing metadata field)
<!-- SECTION:NOTES:END -->
