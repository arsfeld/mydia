---
id: task-75
title: Redesign media files layout using DaisyUI list component
status: Done
assignee: []
created_date: '2025-11-05 15:31'
updated_date: '2025-11-05 15:34'
labels:
  - enhancement
  - ui
  - ux
  - media-files
  - redesign
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Overview
The current media files section uses a table layout which has limitations. Consider redesigning it using DaisyUI's list component with a multi-line card-based layout that provides better usability and visual hierarchy.

## Current Issues with Table Layout
1. **Space constraints**: Table format limits how much information can be displayed comfortably
2. **Hidden actions**: Three-dots dropdown menu requires extra clicks and can be harder to discover
3. **Responsive challenges**: Tables with many columns don't work well on smaller screens
4. **Visual density**: Hard to scan and distinguish between files at a glance

## Proposed Improvements
Consider using DaisyUI's list component: https://daisyui.com/components/list/

### Layout Ideas
- **Multi-line card/list items**: Each file gets its own card or list item with multiple lines
- **Direct action buttons**: Replace dropdown with visible action buttons (View Details, Mark Preferred, Delete)
- **Better information hierarchy**: 
  - Primary line: Quality badge + File name/path (truncated with expand option)
  - Secondary line: Codec info, audio codec, file size
  - Action buttons row: Clearly visible buttons for common actions
- **Visual indicators**: Use badges, icons, and colors to make information scannable
- **Expandable details**: Allow expanding to see full file path and additional metadata

### Example Structure
```html
<ul class="menu bg-base-200 w-full rounded-box">
  <li>
    <div class="flex flex-col gap-2 p-4">
      <!-- Top row: Quality + Path -->
      <div class="flex items-center gap-2">
        <span class="badge badge-primary">1080p</span>
        <span class="text-sm font-mono truncate flex-1" title="full path">
          /movies/Movie.Name.1080p.x265.mkv
        </span>
      </div>
      <!-- Middle row: Technical details -->
      <div class="flex gap-4 text-xs text-base-content/70">
        <span>Codec: x265</span>
        <span>Audio: AAC 5.1</span>
        <span>Size: 4.2 GB</span>
      </div>
      <!-- Bottom row: Actions -->
      <div class="flex gap-2">
        <button class="btn btn-ghost btn-xs">
          <icon>info</icon> Details
        </button>
        <button class="btn btn-ghost btn-xs">
          <icon>star</icon> Prefer
        </button>
        <button class="btn btn-error btn-ghost btn-xs">
          <icon>trash</icon> Delete
        </button>
      </div>
    </div>
  </li>
</ul>
```

## Benefits
- **Better UX**: Actions are immediately visible, no hidden menus
- **More readable**: Multi-line layout allows full path visibility with expand/collapse
- **Mobile friendly**: Stacks naturally on smaller screens
- **Scannable**: Easier to compare multiple files at a glance
- **Modern appearance**: Card-based lists feel more contemporary than tables

## Technical Considerations
- May need to adjust the LiveView to support expand/collapse state per file
- Consider virtualization if there are many files (though this is unlikely for media files)
- Maintain accessibility with proper ARIA labels and keyboard navigation
- Ensure responsive design works on mobile, tablet, and desktop

## Related
- This builds on fixes from task-73
- Consider similar improvements for other tables in the app (episodes, downloads, etc.)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Media files displayed using DaisyUI list or card component instead of table
- [x] #2 Full file path visible or easily expandable without truncation issues
- [x] #3 Action buttons (View Details, Mark Preferred, Delete) directly visible without dropdown menu
- [x] #4 Multi-line layout shows quality, codecs, size, and path in organized hierarchy
- [x] #5 Layout is responsive and works well on mobile, tablet, and desktop screens
- [x] #6 Information is easier to scan and compare between files
- [x] #7 Maintains all existing functionality (view details, mark preferred, delete)
- [x] #8 Accessibility maintained with proper ARIA labels and keyboard navigation
<!-- AC:END -->
