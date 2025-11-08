---
id: task-93
title: Create import flow for scanning and matching media files
status: Done
assignee: []
created_date: '2025-11-05 23:14'
updated_date: '2025-11-05 23:26'
labels:
  - feature
  - import
  - ui
  - metadata
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement a comprehensive import flow that allows users to:

1. Scan the filesystem for media files (movies and TV series)
2. Match discovered files with TMDB metadata
3. Preview and confirm matches before importing
4. Import matched files into the library

This feature should provide a user-friendly interface for bulk importing media files while ensuring accurate metadata matching.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 User can select a filesystem path to scan for media files
- [x] #2 System scans the path and identifies video files
- [x] #3 System attempts to match files with TMDB metadata (movies and TV shows)
- [x] #4 User can review matched files with confidence scores
- [x] #5 User can manually correct or adjust matches
- [x] #6 User can select which files to import
- [x] #7 Import process creates MediaFile records and downloads metadata
- [x] #8 Progress indication during scan and import
- [x] #9 Error handling for failed matches or import errors
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

Created a comprehensive import flow with the following components:

### Backend (`lib/mydia_web/live/import_media_live/index.ex`)
- Multi-step workflow: Path Selection → Scanning → Matching → Review → Import → Complete
- Uses existing infrastructure: Library.Scanner, MetadataMatcher, MetadataEnricher
- Async processing for scanning and matching to avoid blocking the UI
- Automatic confidence-based file selection (auto-selects files with >80% confidence)
- Batch import with progress tracking

### Frontend (`lib/mydia_web/live/import_media_live/index.html.heex`)
- Clean step-by-step UI with progress indicator
- Path selection from manual input or existing library paths
- File list with match details, confidence scores, and TMDB metadata preview
- Checkbox-based file selection with "Select All" and "Deselect All" options
- Real-time progress during import
- Summary statistics at completion

### Route
- Added `/import` route to authenticated session in router

### Key Features
- Displays discovered files with metadata (size, path)
- Shows TMDB match confidence scores with color-coded badges
- Previews matched metadata with poster, title, year, and overview
- Distinguishes between movies and TV shows
- Handles unmatched files gracefully
- Provides import progress and success/failure statistics

## Navigation Added

Added "Import Files" buttons to make the feature discoverable:

1. **Dashboard** - Added a "Quick Actions" section with Import Files card
2. **Movies Page** - Added "Import Files" button next to "Add Movie" button
3. **TV Shows Page** - Added "Import Files" button next to "Add Series" button

Users can now easily access the import flow from multiple entry points in the UI.

## Duplicate Prevention Added

Updated the import flow to skip files already in the library:

**Backend Changes:**
- Before matching, checks all existing media files in the database
- Filters out files with paths that already exist
- Tracks skipped count in scan statistics

**UI Updates:**
- Shows "Already in Library" stat (only when > 0) in the review screen
- Displays info alert during matching phase if files were skipped
- Displays info alert in review screen explaining why files were skipped
- Updated stats labels for clarity ("New Files" instead of "Total Files")

This prevents duplicate imports and provides clear feedback to users about why certain files weren't included in the import process.
<!-- SECTION:NOTES:END -->
