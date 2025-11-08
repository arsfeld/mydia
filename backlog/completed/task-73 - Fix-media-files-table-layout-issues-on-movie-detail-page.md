---
id: task-73
title: Fix media files table layout issues on movie detail page
status: Done
assignee: []
created_date: '2025-11-05 15:01'
updated_date: '2025-11-05 15:27'
labels:
  - bug
  - ui
  - ux
  - table
  - media-files
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The media files table on the movie detail page has two critical UX issues that make it difficult to use:

## Issues

### 1. Path Column Has Insufficient Space
The file path column is very narrow and doesn't display enough of the path, despite being one of the most important pieces of information for identifying files. Users need to see meaningful portions of the file path to understand where files are located.

### 2. Actions Dropdown Menu Unusable in Scrolling Area
The three-dots menu button opens a dropdown menu, but the menu appears inside the scrolling container. This makes it impossible to click on menu items because they're cut off by the overflow boundary.

## Current Location
- File: `lib/mydia_web/live/media_live/show.html.heex`
- Approximate lines: 350-457 (media files table section)

## Expected Behavior

**Path Column:**
- Should have sufficient width to display meaningful file paths
- Consider making it the widest column since it's the most important
- May need to use `overflow-x-visible` or adjust table layout
- Could use text truncation with ellipsis and full path on hover

**Actions Dropdown:**
- Dropdown menu should be positioned outside/above the scroll container
- Menu items should be fully clickable
- Consider using DaisyUI's dropdown positioning classes
- May need to adjust z-index or use portal-style positioning

## Technical Considerations
- The table is likely in a container with `overflow-x-auto` for horizontal scrolling
- Dropdown menus need `overflow-visible` on parent or absolute positioning
- May need to restructure the table layout for better space allocation
- Consider responsive behavior on mobile devices

## Success Criteria
- Path column displays enough of the file path to be useful (at least 40-50 characters visible)
- Actions dropdown menu is fully accessible and all items are clickable
- Table remains responsive and scrollable on smaller screens
- Layout doesn't break on mobile devices
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Path column has sufficient width to display meaningful file paths (40-50+ characters visible)
- [x] #2 Path column is the widest or one of the widest columns in the table
- [x] #3 Actions dropdown menu opens and displays all menu items outside the scroll container
- [x] #4 All menu items in the actions dropdown are clickable
- [x] #5 Table maintains horizontal scrolling on smaller screens
- [x] #6 Layout works correctly on both desktop and mobile devices
- [x] #7 File path text uses appropriate truncation with full path visible on hover/title
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Fixed both critical UX issues in the media files table on the movie detail page:

### 1. Path Column Width Fix
**Location**: `lib/mydia_web/live/media_live/show.html.heex:386-410`

**Changes**:
- Removed `hidden xl:table-cell` class - path column now visible on all screen sizes
- Changed column width from `max-w-xs` (320px) to `min-w-[300px] max-w-[600px]` 
- Added explicit width constraints to other columns (Quality: `w-24`, Codec: `w-20`, Audio: `w-20`, Size: `w-24`, Actions: `w-20`)
- Path column is now the widest column by design, displaying 50+ characters easily
- Wrapped path text in `<div class="truncate">` for proper ellipsis
- Added `title={file.path}` to show full path on hover

### 2. Actions Dropdown Menu Fix
**Location**: `lib/mydia_web/live/media_live/show.html.heex:378, 413-419`

**Changes**:
- Changed dropdown positioning from `dropdown-end` to `dropdown-top dropdown-end`
- Added `pt-32 -mt-32` to the overflow container (line 378) - this creates vertical padding space above the table for the dropdown to render, while the negative margin keeps the visual layout unchanged
- This allows the dropdown menu to appear outside the clipping boundary of `overflow-x-auto`
- Increased z-index from `z-[1]` to `z-50` for proper layering above other content
- Added `shadow-lg` and `border border-base-300` for better visual distinction
- All three menu items (View Details, Mark Preferred, Delete File) are now fully clickable

### 3. Additional Improvements
- Made Quality badge smaller (`badge-sm`) for better compactness
- Added `whitespace-nowrap` to Size column to prevent wrapping
- Adjusted responsive breakpoints: Codec visible on lg+ screens, Audio on xl+ screens
- Maintained `overflow-x-auto` wrapper for horizontal scrolling on mobile devices

### Technical Solution Details
The key to fixing the dropdown clipping issue was the `pt-32 -mt-32` technique:
- `pt-32` adds 8rem (128px) of padding above the table content
- `-mt-32` applies a negative margin to offset the padding visually
- This creates "invisible space" above the table that's inside the overflow container
- The dropdown can now render into this space without being clipped
- The visual appearance remains unchanged due to the negative margin

### Testing
- Compiled successfully with no template errors
- Code passes formatting checks
- Dropdown menu confirmed working and fully clickable
- All acceptance criteria verified and met
<!-- SECTION:NOTES:END -->
