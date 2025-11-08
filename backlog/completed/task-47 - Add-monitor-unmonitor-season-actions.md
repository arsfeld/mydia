---
id: task-47
title: Add monitor/unmonitor season actions
status: Done
assignee: []
created_date: '2025-11-04 21:43'
updated_date: '2025-11-04 23:32'
labels:
  - enhancement
  - feature
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add functionality to monitor or unmonitor all episodes in a season with a single action. This will improve bulk management of TV show episodes.

## Feature Requirements

### Monitor Season
- Add "Monitor Season" button/action at the season level
- When clicked, set all episodes in that season to monitored=true
- Provide visual feedback that the operation completed

### Unmonitor Season  
- Add "Unmonitor Season" button/action at the season level
- When clicked, set all episodes in that season to monitored=false
- Provide visual feedback that the operation completed

## UI Considerations
- Place season-level actions prominently near the season header
- Use clear icons/labels (e.g., "Monitor All", "Unmonitor All", or checkbox icon)
- Show loading state during bulk update
- Update all episode UI states after completion
- Consider showing a count of affected episodes in confirmation/feedback

## Implementation Notes
- Add bulk update function in Media context: `update_season_monitoring(media_item_id, season_number, monitored)`
- Add LiveView event handler for season monitoring toggle
- Update all episode records for the given season in a single transaction
- Broadcast update to refresh UI
- Consider using optimistic UI updates for better UX
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Can monitor all episodes in a season with one action
- [x] #2 Can unmonitor all episodes in a season with one action
- [x] #3 UI shows loading state during bulk update
- [x] #4 All episode states update after operation
- [x] #5 Visual feedback confirms operation completed
- [x] #6 Works reliably for seasons with many episodes
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Add bulk update function in Media context: `update_season_monitoring(media_item_id, season_number, monitored)`
- Add LiveView event handler for season monitoring toggle
- Update all episode records for the given season in a single transaction
- Broadcast update to refresh UI
- Consider using optimistic UI updates for better UX
<!-- SECTION:DESCRIPTION:END -->
<!-- SECTION:NOTES:END -->
