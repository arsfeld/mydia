---
id: task-72
title: Convert vertical timeline to horizontal scrollable timeline for media history
status: Done
assignee: []
created_date: '2025-11-05 14:54'
updated_date: '2025-11-05 14:58'
labels:
  - ui
  - enhancement
  - daisyui
  - timeline
  - history
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current vertical timeline on TV show and movie details pages with a horizontal, scrollable timeline that displays recent events on the left side with the ability to scroll right to view the complete history.

## Context

Task-65 implemented a vertical timeline using DaisyUI's timeline component for media history. While functional, a horizontal timeline would provide several UX benefits:

- Better use of horizontal screen space (especially on wide displays)
- More natural chronological reading (left-to-right for recent → older)
- Compact vertical footprint, leaving more room for other content
- Scrollable design allows unlimited history without page bloat

## Current Implementation

The existing vertical timeline is implemented in:
- `lib/mydia_web/live/media_live/show.html.heex:438-498`
- Uses `timeline timeline-vertical timeline-snap-icon` classes
- Displays all events in a top-to-bottom format

## Proposed Design

**Layout:**
- Horizontal timeline container with overflow-x-auto for scrolling
- Recent events positioned on the left (newest first)
- Scroll right to see older events
- Fixed height container to maintain layout consistency

**Visual Elements:**
- Timeline markers connected by horizontal line
- Events positioned above/below the timeline alternately (or all above for simplicity)
- Compact event cards with key information
- Icons for event types
- Color-coded status indicators

**Interaction:**
- Smooth scroll behavior
- Optional scroll buttons for better discoverability
- Mobile-friendly touch scrolling
- Auto-scroll to newest event on page load

## Technical Considerations

- May need custom CSS for horizontal timeline (DaisyUI's default is vertical)
- Consider using Tailwind's scroll-snap utilities for smooth navigation
- Ensure responsive behavior on mobile (may need different layout)
- Maintain existing color coding and icon system
- Preserve real-time updates via PubSub

## Example Structure

```html
<div class="w-full overflow-x-auto">
  <div class="flex gap-4 min-w-max p-4">
    <!-- Timeline events flow left to right -->
    <div class="relative flex flex-col items-center">
      <div class="card compact bg-base-200 w-64">
        <div class="card-body">
          <div class="text-xs opacity-70">2 hours ago</div>
          <div class="font-semibold">Download Completed</div>
          <div class="text-sm">The.Matrix.1999.1080p.mkv</div>
        </div>
      </div>
      <div class="w-2 h-2 rounded-full bg-success"></div>
      <div class="h-0.5 w-full bg-success"></div>
    </div>
    <!-- More events... -->
  </div>
</div>
```

## Benefits

- Better space utilization on wide screens
- More intuitive chronological flow (left = recent, right = older)
- Reduced vertical scroll requirements on detail pages
- Modern, engaging UI pattern
- Unlimited history without page length concerns
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Timeline displays horizontally with recent events on the left
- [x] #2 Smooth horizontal scrolling enabled with overflow-x-auto
- [x] #3 Timeline maintains all event types from vertical implementation (added, downloaded, imported, etc.)
- [x] #4 Events display with icons, timestamps, status colors, and metadata
- [x] #5 Horizontal timeline uses fixed height to maintain consistent layout
- [x] #6 Mobile responsive design (may stack or adapt layout for narrow screens)
- [x] #7 Auto-scrolls to show most recent events on page load
- [x] #8 Timeline line visually connects all events horizontally
- [x] #9 Preserves real-time PubSub updates from existing implementation
- [x] #10 Works on both movie and TV show detail pages
<!-- AC:END -->
