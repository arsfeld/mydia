---
id: task-116.1
title: Add release validation to reject invalid/hashed torrents
status: Done
assignee:
  - Claude
created_date: '2025-11-08 02:18'
updated_date: '2025-11-08 02:35'
labels: []
dependencies: []
parent_task_id: task-116
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Implement pre-filtering to reject invalid releases before attempting matching, similar to Radarr's Parser validation.

**Invalid patterns to detect**:
- Hashed releases (32/24-char hex strings in brackets)
- Titles with only numbers (no alphanumeric content)
- Password-protected yenc releases
- Reversed title formats (p027, p0801 patterns)
- Releases with zero meaningful content

**Implementation approach**:
- Add `ReleaseValidator` module with rejection rules
- Integrate into TorrentParser before parsing logic
- Add validation to search result processing pipeline

**Files to modify**:
- `lib/mydia/downloads/torrent_parser.ex` - Add validation step
- Create `lib/mydia/downloads/release_validator.ex` - New validation module
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Hashed release names like '[A1B2C3D4E5F6...]' are rejected
- [x] #2 Releases with only numeric titles are rejected
- [x] #3 Password-protected releases are rejected
- [x] #4 Reversed title patterns are detected and rejected
- [x] #5 Valid releases continue to pass validation
- [x] #6 Tests cover all rejection patterns
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

**Changes made:**

1. **ReleaseValidator module** - Created comprehensive validation system:
   - Hashed releases (24-32 char hex strings in brackets)
   - Numeric-only titles (no meaningful text)
   - Password-protected releases
   - Reversed patterns (p0801 style)
   - Yenc binary patterns
   - Releases with no meaningful content

2. **TorrentParser integration** - Added validation as first step:
   - Validates before cleaning and parsing
   - Returns specific error reasons for rejected releases
   - Preserves existing parsing logic for valid releases

3. **Comprehensive test suite** - 42 tests covering:
   - All rejection patterns
   - Valid releases that should pass
   - Edge cases and unicode handling
   - All tests passing ✓

**Test Results:**
- ReleaseValidator tests: 42/42 passing ✓
- TorrentParser tests: 36/36 passing ✓
- No regressions in existing functionality

**Benefits:**
- Prevents fake/malicious torrents from being processed
- Saves CPU time by rejecting bad releases early
- Clear error messages for debugging
- Easily extensible for new patterns
<!-- SECTION:NOTES:END -->
