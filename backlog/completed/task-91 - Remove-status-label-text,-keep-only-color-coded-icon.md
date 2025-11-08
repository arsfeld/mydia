---
id: task-91
title: 'Remove status label text, keep only color-coded icon'
status: Done
assignee: []
created_date: '2025-11-05 21:10'
updated_date: '2025-11-05 21:15'
labels:
  - ui
  - ux
  - enhancement
  - tv-shows
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, episode status is displayed with both a color-coded icon and text label (e.g., "Downloaded", "Missing", "Downloading"). This takes up unnecessary space in the UI, especially in table views where space is at a premium.

The status is already clearly communicated through:
1. The color-coded icon (check-circle for downloaded, x-circle for missing, etc.)
2. The icon color (success green, error red, warning yellow, etc.)
3. The tooltip that shows detailed status information

**Proposed Change:**
Remove the text label from episode status badges and show only the color-coded icon. The tooltip will continue to provide detailed status information on hover.

**Affected Areas:**
- TV show detail page episode tables
- Any other locations where episode status is displayed with icon + text

**Benefits:**
- More compact UI with better use of space
- Cleaner, more modern appearance
- Maintains full information accessibility through tooltips
- Consistent with common UI patterns where icons alone convey status
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Status badges show only the color-coded icon without text
- [x] #2 Icon size is appropriate and clearly visible
- [x] #3 Tooltip continues to show detailed status information on hover
- [x] #4 Change applies consistently across all status display locations
- [x] #5 Status remains easily distinguishable by color and icon shape
<!-- AC:END -->
