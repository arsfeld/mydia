---
id: task-109.4
title: Build activity feed LiveView with real-time updates
status: Done
assignee: []
created_date: '2025-11-06 18:46'
updated_date: '2025-11-06 19:41'
labels:
  - ui
  - liveview
  - frontend
dependencies: []
parent_task_id: task-109
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the activity feed UI to display recent events with filtering and real-time updates via PubSub.

## Components

**ActivityLive.Index LiveView:**
- Display recent events (50 most recent)
- Filter by category (all, media, downloads, library, system, auth)
- Real-time updates via PubSub subscription
- Use LiveView streams for efficient updates
- Event list with icons, timestamps, descriptions

**Event Display Component:**
- Format event descriptions based on type
- Show actor (user/system/job)
- Display relevant metadata (titles, sizes, etc.)
- Color coding by severity
- Relative timestamps ("2 minutes ago")

**Navigation:**
- Add "Activity" link to main navigation
- Route: `/activity`

## UI Design

- Clean timeline/feed layout with DaisyUI components
- Category filter tabs/badges
- Event cards with icons and metadata
- Empty state for no events
- Responsive design
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Activity feed page accessible at /activity
- [ ] #2 Events displayed in reverse chronological order
- [ ] #3 Category filtering works (all, media, downloads, etc.)
- [ ] #4 New events appear in real-time via PubSub
- [ ] #5 Event descriptions are human-readable and formatted
- [ ] #6 UI uses DaisyUI components for consistent styling
- [ ] #7 Responsive design works on mobile and desktop
<!-- AC:END -->
