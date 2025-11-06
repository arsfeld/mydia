---
id: task-92
title: Quick add settings collapsed by default in the add screen
status: Done
assignee: []
created_date: '2025-11-05 23:10'
updated_date: '2025-11-05 23:12'
labels:
  - ui
  - ux
  - enhancement
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Settings section should be collapsed by default when opening the add screen to provide a cleaner initial view and reduce visual clutter. Users can expand settings when needed.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Updated the Quick Add Settings section in add_media_live/index.html.heex to use DaisyUI's collapse component. The section is now:
- Wrapped in a `collapse collapse-arrow` component
- Collapsed by default (unchecked checkbox state)
- Has a clickable title bar with an arrow indicator
- Users can expand/collapse by clicking on the title

Key changes:
- Changed outer div to `<div class="collapse collapse-arrow bg-base-100 rounded-lg mb-6 shadow-lg">`
- Added unchecked checkbox control: `<input type="checkbox" id="quick-add-settings-toggle" />`
- Moved title to `<div class="collapse-title">Quick Add Settings</div>`
- Wrapped content in `<div class="collapse-content">...</div>`

The implementation uses pure DaisyUI components without requiring any JavaScript changes.
<!-- SECTION:NOTES:END -->
