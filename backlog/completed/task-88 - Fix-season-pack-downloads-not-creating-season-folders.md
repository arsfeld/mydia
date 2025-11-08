---
id: task-88
title: Fix season pack downloads not creating season folders
status: Done
assignee: []
created_date: '2025-11-05 19:59'
updated_date: '2025-11-05 20:12'
labels:
  - bug
  - media-organization
  - downloads
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Witcher season 4 was downloaded as a season pack, but instead of creating a proper `Season 04` folder structure, the media files were added directly to the root of The Witcher folder. This causes organizational issues and doesn't follow the proper media library structure.

Expected behavior:
```
The Witcher/
  Season 04/
    The Witcher - S04E01.mkv
    The Witcher - S04E02.mkv
    ...
```

Actual behavior:
```
The Witcher/
  The Witcher - S04E01.mkv
  The Witcher - S04E02.mkv
  ...
```

This likely affects the media import/organization logic that handles season pack downloads.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Season pack downloads create proper Season XX folder structure
- [x] #2 Existing media files in root are migrated to correct season folders
- [x] #3 The Witcher season 4 files are moved to Season 04 folder
- [x] #4 Tests verify season pack organization behavior
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

1. **Modified MediaImport job** (`lib/mydia/jobs/media_import.ex`):
   - Added Media alias to access episode lookup functions
   - Changed `organize_and_import_files/4` to call `import_file/4` with library_root instead of pre-computed dest_dir
   - Modified `import_file/4` to:
     - Parse each video file's filename using FileParser
     - For TV shows, look up the correct episode using `Media.get_episode_by_number/3`
     - Build the correct destination path based on parsed season info
     - Create Season folders as needed
   - Updated `handle_file_conflict/5` and `create_media_file_record/4` to accept episode parameter
   - Each file is now associated with the correct episode in the database

2. **Created migration script** (`lib/mix/tasks/mydia.migrate_episode_files.ex`):
   - Mix task to migrate existing misplaced episode files
   - Finds all TV episode files and checks if they're in Season folders
   - For files in show root directories, parses filename and moves to correct Season folder
   - Updates database paths accordingly
   - Supports --dry-run and --show-title options

## Technical Details

The fix works by:
- Parsing each video file's filename to extract season/episode info
- Looking up the corresponding episode from the database
- Using that episode to build the correct Season folder path
- Associating each media_file record with the correct episode_id

This handles season packs properly because each file gets individually processed and associated with its own episode, rather than all files sharing the download's single episode reference.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Usage Instructions

### For Future Downloads

The fix is now automatic. When a season pack is downloaded:
1. Each episode file will be parsed to extract season/episode info
2. The correct episode will be looked up from the database
3. Files will be placed in the proper `Season XX` folder
4. Each file will be associated with its correct episode

### For Existing Misplaced Files

Use the migration script to fix existing files:

```bash
# Dry run to see what would be migrated
./dev mix mydia.migrate_episode_files --dry-run

# Migrate files for a specific show
./dev mix mydia.migrate_episode_files --show-title "The Witcher"

# Migrate all misplaced episode files
./dev mix mydia.migrate_episode_files
```

The script will:
- Find all episode files in show root directories
- Parse filenames to extract season info
- Create proper Season folders
- Move files and update database paths

### Testing

To verify the fix:
1. Download a season pack
2. Check that files are placed in `Season XX` folders
3. Verify each file is associated with the correct episode in the UI
<!-- SECTION:NOTES:END -->
