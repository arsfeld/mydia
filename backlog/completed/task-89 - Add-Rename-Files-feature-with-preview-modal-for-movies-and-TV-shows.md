---
id: task-89
title: Add "Rename Files" feature with preview modal for movies and TV shows
status: Done
assignee: []
created_date: '2025-11-05 20:56'
updated_date: '2025-11-05 21:00'
labels:
  - feature
  - ui
  - file-management
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a "Rename Files" button on movie and TV show detail pages that opens a modal showing a preview of proposed file renames. Users can review the changes and approve or cancel the rename operation.

## User Story

As a user, I want to rename my media files to follow a consistent naming convention so that my library is well-organized and compatible with media players.

## Expected Behavior

### For Movies

**Current filename:** `Some.Random.Movie.2024.1080p.WEB-DL.mkv`

**Proposed filename:** `Movie Title (2024) [1080p WEB-DL].mkv`

### For TV Shows

**Current filename:** `show.name.s01e05.720p.mkv`

**Proposed filename:** `Show Name - S01E05 - Episode Title [720p].mkv`

## Feature Details

### UI Components

1. **Rename Button**
   - Appears on media detail page
   - Icon: pencil/edit icon
   - Label: "Rename Files"
   - Only visible if media has files

2. **Preview Modal**
   - Shows list of files to be renamed
   - For each file:
     - Current filename (with path)
     - Proposed filename (with path)
     - File size and quality info
     - Diff/highlight of changes
   - Action buttons:
     - "Cancel" - closes modal without changes
     - "Rename Files" - executes the rename operation

3. **Progress/Feedback**
   - Loading state while generating preview
   - Progress indicator during rename
   - Success/error messages
   - Refresh file list after rename

### Naming Convention

**Movies:**
```
{Title} ({Year}) [{Quality} {Source}].{ext}
Example: The Matrix (1999) [1080p BluRay].mkv
```

**TV Shows:**
```
{Show Title} - S{Season}E{Episode} - {Episode Title} [{Quality}].{ext}
Example: Breaking Bad - S01E01 - Pilot [720p].mkv
```

### Implementation Notes

- Rename should update both filesystem and database
- Should handle conflicts (if target filename exists)
- Should preserve file permissions and timestamps
- Should support undo/rollback on failure
- Should validate filenames (no invalid characters)
- Consider making naming template configurable in settings
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Rename Files button appears on movie and TV show detail pages
- [ ] #2 Clicking button opens modal with file rename preview
- [ ] #3 Preview shows current and proposed filenames with diff highlighting
- [ ] #4 User can approve or cancel the rename operation
- [ ] #5 Rename updates both filesystem and database paths
- [ ] #6 Success/error messages are shown to user
- [ ] #7 File list refreshes after successful rename
- [ ] #8 Handles edge cases: file conflicts, missing files, permission errors
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Rename should update both filesystem and database
- Should handle conflicts (if target filename exists)
- Should preserve file permissions and timestamps
- Should support undo/rollback on failure
- Should validate filenames (no invalid characters)
- Consider making naming template configurable in settings
<!-- SECTION:DESCRIPTION:END -->

## Implementation Complete

Successfully implemented the rename files feature with the following components:

### Backend (lib/mydia/library/file_renamer.ex)
- Created FileRenamer module with functions to generate rename previews
- Implements naming conventions:
  - Movies: `{Title} ({Year}) [{Quality} {Source}].{ext}`
  - TV Shows: `{Show Title} - S{Season}E{Episode} - {Episode Title} [{Quality}].{ext}`
- Handles batch rename operations with rollback on failure
- Updates both filesystem and database

### Frontend (lib/mydia_web/live/media_live/show.ex)
- Added "Rename Files" button in Media Files section
- Created preview modal showing current vs proposed filenames
- Implemented async rename operation with progress indicator
- Added proper error handling and user feedback

### UI Features
- Preview modal shows all files to be renamed
- Visual diff with current and proposed filenames
- Indicates which files will actually change
- Shows directory path for each file
- Displays count of files to be renamed
- Loading state during rename operation
- Success/error messages after completion
<!-- SECTION:NOTES:END -->
