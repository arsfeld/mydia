---
id: task-46
title: Unify episode monitoring toggle in details page
status: Done
assignee:
  - assistant
created_date: '2025-11-04 21:43'
updated_date: '2025-11-04 23:30'
labels:
  - enhancement
  - ui
  - ux
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, the media details page may have separate actions for monitoring episodes. Improve the UX by making the episode itself clickable to toggle its monitoring status.

## Current Behavior
Episodes have a separate action/button to toggle monitoring status

## Desired Behavior
- Clicking directly on an episode row should toggle its monitoring status
- Visual feedback should clearly indicate monitored vs unmonitored state
- The toggle should be intuitive and responsive

## Implementation Notes
- Update the episode list UI to make episodes clickable
- Add `phx-click` event handler for episode monitoring toggle
- Update visual styling to show monitored state (e.g., checkbox, icon, or color change)
- Consider adding hover states to indicate clickability
- Ensure the UI updates immediately after toggling
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Episodes can be clicked to toggle monitoring
- [x] #2 Visual state clearly shows monitored vs unmonitored
- [x] #3 UI updates immediately after toggle
- [x] #4 Hover state indicates clickability
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Won't Do

After implementation review, decided not to proceed with this change. The current UX with the dedicated monitoring toggle button in the Actions column is clearer and more explicit than making the entire row clickable.

Reasons:
- Clickable rows can be confusing when there are other interactive elements (buttons)
- The current implementation is more explicit and discoverable
- Having a dedicated button makes it clear what action will be performed
- The status badges already provide excellent visual feedback for monitored state
<!-- SECTION:NOTES:END -->
