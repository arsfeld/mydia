---
id: task-90
title: Fix TV show seasons collapsing when taking actions on non-last seasons
status: Done
assignee: []
created_date: '2025-11-05 20:57'
updated_date: '2025-11-05 21:01'
labels:
  - bug
  - ui
  - ux
  - tv-shows
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently, when performing actions on TV show episodes in any season other than the last season, that season automatically collapses. This creates a frustrating user experience as users lose their place and have to re-expand the season to continue working.

The collapsible behavior should either:
1. Maintain the expanded/collapsed state of seasons after actions are performed
2. Be removed entirely in favor of always-expanded seasons
3. Use a more intelligent state management that doesn't collapse on user actions

This affects any actions taken within season sections, such as:
- Downloading episodes
- Marking episodes as monitored/unmonitored
- Editing episode metadata
- Any other interactive elements within season sections

The expected behavior is that seasons should remain in their current expanded/collapsed state unless the user explicitly clicks the collapse/expand control.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Actions taken on episodes in any season do not cause that season to collapse
- [x] #2 Season expanded/collapsed state persists across user interactions
- [x] #3 Users can still manually expand/collapse seasons if the collapsible UI is retained
- [x] #4 The fix applies to all interactive elements within season sections
- [x] #5 No regression in other TV show detail page functionality
<!-- AC:END -->
