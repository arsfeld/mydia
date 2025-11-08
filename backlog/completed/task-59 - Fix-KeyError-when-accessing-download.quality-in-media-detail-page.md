---
id: task-59
title: Fix KeyError when accessing download.quality in media detail page
status: Done
assignee: []
created_date: '2025-11-05 03:24'
updated_date: '2025-11-05 03:26'
labels:
  - bug
  - ui
  - downloads
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The media detail page crashes with a KeyError when trying to display downloads because the template at `lib/mydia_web/live/media_live/show.html.heex:461` attempts to access `download.quality`, but the `Mydia.Downloads.Download` schema doesn't have a `:quality` field.

**Error Details:**
- URL: `/media/{id}`
- Error: `key :quality not found in: %Mydia.Downloads.Download{...}`
- Location: `show.html.heex:461` in the downloads table rendering

**Context:**
The downloads table includes a quality column that checks `if download.quality do` and displays a badge, but this field doesn't exist in the Download schema.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Media detail page loads successfully without KeyError
- [x] #2 Downloads table displays correctly (with quality info if field exists, or gracefully handles missing field)
- [x] #3 Existing tests pass and new test verifies the fix
- [x] #4 Solution is consistent with codebase patterns for handling optional fields
<!-- AC:END -->
