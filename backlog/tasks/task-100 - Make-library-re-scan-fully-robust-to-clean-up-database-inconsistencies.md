---
id: task-100
title: Make library re-scan fully robust to clean up database inconsistencies
status: Done
assignee: []
created_date: '2025-11-06 04:43'
updated_date: '2025-11-06 04:51'
labels:
  - enhancement
  - library
  - data-integrity
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The library re-scan should be the ultimate "fix everything" operation that resolves all database inconsistencies by thoroughly scanning all files and matching them properly.

## Current Issues

1. **Orphaned files** - Media files with `media_item_id` but no `episode_id` for TV shows
2. **Mismatched files** - Files associated with wrong episodes or shows
3. **Missing associations** - Files that should be linked to episodes but aren't
4. **Stale data** - Outdated metadata or incorrect folder organization

## Desired Behavior

The re-scan operation should:

1. **Scan all files thoroughly** - Walk through entire library paths
2. **Re-parse all filenames** - Extract season/episode info fresh
3. **Re-match to database** - Find correct media_item/episode associations
4. **Fix orphaned files** - Associate orphaned files with correct episodes
5. **Remove stale entries** - Clean up database entries for files that no longer exist
6. **Handle edge cases** - Season packs, multi-episode files, special episodes, etc.
7. **Be idempotent** - Running multiple times should converge to clean state
8. **Report results** - Show what was fixed, what couldn't be matched

## Context

This was identified after discovering that season pack imports were creating orphaned files. While the import process has been fixed (see MediaImport changes for season pack detection), the re-scan should be robust enough to clean up any existing issues and handle future edge cases.

The re-scan should be the "nuclear option" that users can trust to fix any database/file sync issues.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Re-scan fixes orphaned TV show files by matching them to correct episodes
- [x] #2 Re-scan removes database entries for files that no longer exist on disk
- [x] #3 Re-scan updates file associations when season/episode info changes
- [x] #4 Re-scan is idempotent - running twice produces same result
- [x] #5 Re-scan reports summary of what was fixed/cleaned up
- [x] #6 Re-scan handles season packs correctly
- [x] #7 Re-scan handles multi-episode files correctly
- [x] #8 Re-scan validates all file paths and removes invalid entries
<!-- AC:END -->
