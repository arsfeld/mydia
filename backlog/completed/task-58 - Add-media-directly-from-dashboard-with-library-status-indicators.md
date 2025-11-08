---
id: task-58
title: Add media directly from dashboard with library status indicators
status: Done
assignee: []
created_date: '2025-11-05 03:10'
updated_date: '2025-11-05 03:16'
labels:
  - enhancement
  - ui
  - dashboard
  - ux
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enhance the dashboard trending sections to allow users to add movies and TV shows directly from the dashboard, and show visual indicators for items already in the library.

## Features

**Add to Library from Dashboard:**
- Add clickable action buttons/icons on trending movie/TV show cards
- Support quick-add functionality without navigating away from dashboard
- Show confirmation/feedback when adding media
- Handle both movies and TV shows

**Library Status Indicators:**
- Show visual indicator (badge, icon, or overlay) on trending items already in the library
- Different states:
  - Not in library (default, show "Add" button)
  - In library and monitored (show checkmark/badge)
  - In library but not monitored (show different indicator)
- Real-time updates when items are added

**Implementation Considerations:**
- Query existing library items on dashboard load to check status
- Efficient lookup (avoid N+1 queries) - perhaps load all TMDB IDs in library
- Use LiveView events for adding media
- Update dashboard state after successful addition
- Handle errors gracefully (duplicate adds, API failures, etc.)
- Consider adding to existing Media.add_movie/add_tv_show flows

## User Experience
- One-click add from trending content
- Clear visual feedback about what's already in library
- Reduces friction for new users discovering content
- Helps existing users quickly see what they already have
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Trending movie cards show 'Add to Library' button when not in library
- [x] #2 Trending TV show cards show 'Add to Library' button when not in library
- [x] #3 Cards for items already in library display a visual indicator (badge/icon)
- [x] #4 Clicking 'Add to Library' adds the media item without page navigation
- [x] #5 Success/error feedback is displayed after add attempt
- [x] #6 Dashboard state updates to show library indicator after successful add
- [x] #7 Library status check is performant (no N+1 queries)
- [x] #8 Different visual states for monitored vs unmonitored library items
<!-- AC:END -->
