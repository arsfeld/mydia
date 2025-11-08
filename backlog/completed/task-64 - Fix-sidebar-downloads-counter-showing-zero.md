---
id: task-64
title: Fix sidebar downloads counter showing zero
status: Done
assignee: []
created_date: '2025-11-05 04:50'
updated_date: '2025-11-05 14:26'
labels:
  - bug
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The downloads counter in the sidebar navigation is always showing zero, even when there are active downloads. The counter should display the current number of active/in-progress downloads to give users visibility into ongoing activity.

This likely requires:
- Investigating how the counter is currently calculated
- Ensuring it queries the correct download status/state
- Possibly adding real-time updates via PubSub when downloads change
- Testing that the counter updates when downloads are added, completed, or cancelled
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Counter shows accurate count of active downloads on page load
- [x] #2 Counter updates in real-time when downloads are added
- [x] #3 Counter updates in real-time when downloads complete or are cancelled
- [x] #4 Counter only counts downloads in active/in-progress states (not completed or failed)
<!-- AC:END -->
