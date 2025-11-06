---
id: task-103
title: Add monitoring toggle functionality to poster icons
status: Done
assignee: []
created_date: '2025-11-06 14:56'
updated_date: '2025-11-06 16:13'
labels:
  - feature
  - ui
  - monitoring
  - poster
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow users to toggle monitoring/unmonitoring directly through the monitoring icon displayed on TV series or movie posters. 

Currently, users likely need to navigate to a detail page or use a different interface to change monitoring status. Adding click/tap functionality to the icon on the poster itself would provide a more convenient and intuitive user experience.

The icon should:
- Show current monitoring status visually
- Toggle monitoring on/off when clicked
- Provide visual feedback (e.g., animation, color change) on state change
- Update the monitoring status in the backend
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Clicking the monitoring icon on a poster in grid view toggles the monitoring status
- [x] #2 The icon updates immediately to reflect the new state (solid bookmark when monitored, outline when not)
- [x] #3 A success message is displayed when the monitoring status changes
- [x] #4 The media item's monitoring status is updated in the database
- [x] #5 Clicking the icon does not navigate to the detail page
- [x] #6 The toggle works for both movies and TV series
- [x] #7 Visual feedback is provided during the state change (smooth transition)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Update Grid View Template
**File**: `lib/mydia_web/live/media_live/index.html.heex`

- Convert static monitoring icon div to clickable button
- Add `phx-click="toggle_item_monitored"` with `phx-value-id={item.id}`
- Show icon for both monitored and unmonitored states:
  - Monitored: `hero-bookmark-solid` with primary color
  - Unmonitored: `hero-bookmark` outline with neutral color
- Add hover effects and transitions for visual feedback
- Ensure click doesn't trigger navigation to detail page

### 2. Add Event Handler
**File**: `lib/mydia_web/live/media_live/index.ex`

- Create `handle_event("toggle_item_monitored", %{"id" => id}, socket)` function
- Call `Media.update_media_item/2` to toggle monitored status
- Update the item in the stream with `stream_insert/3`
- Display success flash message
- Pattern after the detail page's `toggle_monitored` handler

### 3. Technical Approach
- Use existing `Media.update_media_item/2` backend function
- Update single stream item efficiently without full reload
- Follow Phoenix LiveView event handling best practices
- Add smooth CSS transitions for state changes
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

### Changes Made

1. **Template Update** (`lib/mydia_web/live/media_live/index.html.heex:241-263`)
   - Converted static monitoring indicator to clickable button
   - Added `phx-click="toggle_item_monitored"` event handler with item ID
   - Icon now shows for all items (not just monitored ones)
   - Solid bookmark (`hero-bookmark-solid`) for monitored items
   - Outline bookmark (`hero-bookmark`) for unmonitored items
   - Added hover effects (scale, background) and smooth transitions
   - Button properly styled with z-index to ensure clickability

2. **Event Handler** (`lib/mydia_web/live/media_live/index.ex:215-232`)
   - Created `handle_event("toggle_item_monitored", %{"id" => id}, socket)`
   - Fetches media item, toggles monitored status
   - Updates database via `Media.update_media_item/2`
   - Updates UI efficiently using `stream_insert/3`
   - Shows success flash message
   - Handles errors gracefully

### Technical Details
- No full page reload needed (LiveView stream update)
- Event doesn't propagate to parent link (button click is isolated)
- Works for both movies and TV series
- Visual feedback through CSS transitions and hover effects
- Follows Phoenix LiveView best practices

## Bug Fix - Event Propagation

**Issue**: Clicking the monitoring button was navigating to the detail page because the click event bubbled up to the parent `<.link>` element.

**Solution**: Added `onclick="event.stopPropagation()"` to the button (line 247), following the same pattern used by the selection checkbox.

**Result**: Button click now only toggles monitoring status without triggering navigation.

## Bug Fix #2 - Button Position

**Root Cause**: The monitoring button was inside the `<.link>` element (within the `<figure>` tag), so even with `event.stopPropagation()`, the navigation was still triggered.

**Solution**: Moved the monitoring button to be a sibling of the `<.link>` element (lines 224-246), positioned in the parent container just like the selection checkbox. Now the button and link are independent elements.

**Result**: Button clicks are now completely isolated from the link - no navigation occurs when toggling monitoring status.

## Bug Fix #3 - Association Preloading

**Issue**: After clicking the monitoring button, an error occurred: `protocol Enumerable not implemented for #Ecto.Association.NotLoaded<association :media_files is not loaded>`. This happened because the updated item returned from `Media.update_media_item/2` didn't have the same associations preloaded as the original stream items.

**Root Cause**: The template helpers (like `get_quality_badge/1` at line 487) need to access the `media_files` association. The original items are loaded with preloads: `[:media_files, :downloads, episodes: [:media_files, :downloads]]`, but the updated item was missing these.

**Solution**: After updating the item, refetch it with proper preloads using `Media.get_media_item!(id, preload: [...])` before inserting back into the stream (lines 222-225).

**Result**: The monitoring toggle now works without errors, and all template helpers have access to the required associations.
<!-- SECTION:NOTES:END -->
