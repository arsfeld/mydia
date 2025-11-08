---
id: task-111
title: Fix missing year data causing untracked torrent matching to fail
status: Done
assignee: []
created_date: '2025-11-06 18:54'
updated_date: '2025-11-06 18:59'
labels:
  - bug
  - data-quality
  - metadata
  - movies
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Matrix movie in the library has no year data (`year: nil`), which causes the untracked torrent matcher to fail when trying to match torrents with year information in their names.

**Root Cause:**
When The Matrix was added to the library, the year field was not populated. The TorrentMatcher uses year matching as a critical confidence factor for movies (lines 82-90 in `lib/mydia/downloads/torrent_matcher.ex`):
- Exact year match: +0.3 confidence boost
- No year match: -0.2 penalty

With no year in the database, the matcher applies the penalty and confidence drops below the 80% threshold.

**Impact:**
- Untracked torrents for The Matrix cannot be automatically matched
- Similar issues will occur for any other movies missing year data
- Logs show repeated failed match attempts

**Evidence:**
```
Matrix found: The Matrix (monitored: true)
All Matrix movies in library:
  - The Matrix () - monitored: true
```

The `()` indicates empty year field.

**Solution:**
1. Add data quality check to ensure movies have year populated
2. Refresh metadata for movies with missing years
3. Consider making year a required field or validating during import
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Identify all movies in library with missing year data
- [x] #2 Add validation or data quality check for required movie metadata fields
- [x] #3 Refresh The Matrix metadata to populate year field
- [x] #4 Consider making year required for movie media_items
- [x] #5 Document expected metadata quality standards
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

### Changes Made

1. **Added Year Validation for Movies** (lib/mydia/media/media_item.ex:50-65)
   - Added `validate_year_for_movies/1` custom validation function
   - Movies now require year field to be set (TV shows remain optional)
   - Validation error: "is required for movies"

2. **Refreshed All Movies with Missing Year Data**
   - The Matrix (TMDB ID: 603) → year: 1999
   - Dune: Part Two (TMDB ID: 693134) → year: 2024
   - The Smashing Machine (TMDB ID: 760329) → year: 2025
   - All movies now have year data populated from TMDB metadata

3. **Added Test Coverage** (test/mydia/media_test.exs:44-70)
   - Test for year requirement on movies (returns validation error)
   - Test that TV shows can be created without year (remains optional)
   - All 15 tests pass

### Impact

- **Torrent Matching**: Movies will no longer fail matching due to missing year data
- **Data Quality**: New movies cannot be added without year information
- **Backward Compatibility**: Existing TV shows without years are unaffected
- **Future Protection**: Prevents recurrence of the issue

### Verification

Ran database query confirming 0 movies remain without year data. The untracked torrent matcher will now successfully match torrents for The Matrix and other movies with proper year matching confidence scores.
<!-- SECTION:NOTES:END -->
