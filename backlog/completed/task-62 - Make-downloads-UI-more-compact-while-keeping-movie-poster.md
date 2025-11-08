---
id: task-62
title: Make downloads UI more compact while keeping movie poster
status: Done
assignee:
  - Claude
created_date: '2025-11-05 04:33'
updated_date: '2025-11-05 04:51'
labels:
  - ui
  - enhancement
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The downloads page UI currently uses a lot of vertical space for each download item. Redesign the layout to be more compact and efficient, allowing users to see more downloads at once without scrolling. The movie/show poster should be retained as it provides visual context.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Download items take up less vertical space than current implementation
- [x] #2 Movie/show poster remains visible for each download
- [x] #3 All essential information is still easily readable (title, status, progress, ETA, speed, size)
- [x] #4 UI remains responsive and works well on mobile devices
- [x] #5 Design maintains visual hierarchy and usability
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan - Information Dense Layout

### Design Changes

1. **Horizontal layout optimization**
   - Checkbox | Poster | Content area | Action button
   - Action button (X/Retry) positioned at top-right of card
   - Remove dedicated action button section at bottom

2. **Integrate progress bar**
   - Progress bar directly below title (no separate section)
   - Smaller, thinner progress bar (h-1)
   - Progress percentage shown inline with stats

3. **Compact stats layout**
   - Display stats inline: Progress • Speed • Size • ETA • Seeds
   - Use separator dots between stats
   - Single line when possible, wraps on mobile
   - Remove grid layout in favor of inline flow

4. **Title section**
   - Title with badges on same line when space allows
   - Reduce vertical spacing throughout

5. **Overall spacing**
   - Reduce card padding to p-3
   - Reduce gap between elements
   - Tighter spacing between cards

### Expected Results
- Much more information dense without sacrificing readability
- Better use of horizontal space
- More downloads visible at once
- Cleaner, more modern layout

### Files to Modify
- lib/mydia_web/live/downloads_live/index.html.heex
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented information-dense layout using DaisyUI list component:
- Replaced card-based layout with DaisyUI `list` and `list-row` classes
- Checkbox | Poster (w-12) | Content (grows) | Action button layout
- Progress bar integrated directly below title (h-1, compact)
- Stats displayed inline with bullet separators: Progress • Speed • Size • ETA • Seeds
- Action buttons (X for cancel, Retry/Remove for issues) positioned at end of row
- Reduced poster size to w-12 (~48px) for even more compact display
- Hover state on list rows for better interactivity
- All information remains easily readable and accessible

Added selection mode toggle:
- Checkboxes now only appear when user clicks 'Select' button
- Button states: 'Select' → 'Select All'/'Cancel Selection' based on mode
- Selection mode automatically exits after batch operations
- Tab switching resets selection mode

Fixed selection mode UI:
- Moved Select button from floating bottom position to top toolbar
- Fixed checkbox visibility by always rendering but hiding with CSS class instead of conditional rendering (better compatibility with LiveView streams)
- Button integrated with other utility actions in header
<!-- SECTION:NOTES:END -->
