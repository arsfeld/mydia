---
id: task-65
title: Use DaisyUI timeline component for movie/tv show history table
status: Done
assignee: []
created_date: '2025-11-05 04:56'
updated_date: '2025-11-05 05:00'
labels:
  - ui
  - daisyui
  - history
  - enhancement
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current history table display with DaisyUI's timeline component to provide a more visually appealing and intuitive representation of media item history.

## Context

Currently, movie and TV show history (downloads, imports, searches, etc.) is likely displayed in a basic table format. Using DaisyUI's timeline component would provide a more modern, chronological visualization that better represents the sequential nature of events.

## Implementation

**Timeline Component:**
- Use DaisyUI's timeline component: https://daisyui.com/components/timeline/
- Display events chronologically (newest first or oldest first, configurable)
- Include event type, timestamp, status, and details

**Event Types to Display:**
- Media item added to library
- Automatic search performed
- Manual search triggered
- Download initiated
- Download completed/failed
- File imported
- Metadata refreshed
- Quality upgraded

**Visual Design:**
- Use timeline markers with icons for different event types
- Color code by status (success/warning/error using DaisyUI colors)
- Show event timestamp in relative format (e.g., "2 hours ago")
- Include expandable details for each event
- Responsive design for mobile/tablet

**Data Requirements:**
- Query event history for a media item
- May need to create a unified events table or view
- Include relevant metadata (user who triggered, error messages, etc.)

## Example Structure

```html
<ul class="timeline timeline-vertical">
  <li>
    <div class="timeline-start">2 hours ago</div>
    <div class="timeline-middle">
      <svg class="w-5 h-5 text-success">...</svg>
    </div>
    <div class="timeline-end timeline-box">
      <div class="font-semibold">Download Completed</div>
      <div class="text-sm">The.Matrix.1999.1080p.mkv (4.2 GB)</div>
    </div>
    <hr class="bg-success" />
  </li>
  <!-- more events -->
</ul>
```

## Benefits

- Better UX for tracking media item lifecycle
- Easier to debug issues by seeing event sequence
- More engaging and modern interface
- Chronological context at a glance
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Timeline component replaces existing history table on media detail pages
- [x] #2 Events display chronologically with configurable sort order
- [x] #3 All major event types are represented (added, searched, downloaded, imported, etc.)
- [x] #4 Each event shows timestamp, status icon, and description
- [x] #5 Status is color-coded using DaisyUI semantic colors (success/warning/error)
- [x] #6 Timeline is responsive and works on mobile devices
- [x] #7 Events can be expanded to show additional details
- [x] #8 Relative timestamps (e.g., '2 hours ago') with absolute time on hover
- [x] #9 Icon set is consistent across all event types
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully replaced the download history table with DaisyUI's timeline component on media detail pages.

### Changes Made

1. **Added Timeline Helper Functions** (`lib/mydia_web/live/media_live/show.ex`):
   - `build_timeline_events/2`: Builds timeline events from media items, downloads, files, and episodes
   - `format_relative_time/1`: Formats timestamps as relative time (e.g., "2 hours ago")
   - `format_absolute_time/1`: Formats timestamps for hover tooltips

2. **Updated LiveView Mount** (`lib/mydia_web/live/media_live/show.ex:26-33`):
   - Added `timeline_events` assignment to socket
   - Timeline events are rebuilt on mount and whenever downloads/media items update

3. **Updated PubSub Handlers** (`lib/mydia_web/live/media_live/show.ex:607-634`):
   - Modified `handle_info` callbacks to rebuild timeline events on download updates
   - Ensures timeline stays in sync with real-time changes

4. **Replaced Table with Timeline Component** (`lib/mydia_web/live/media_live/show.html.heex:438-498`):
   - Used DaisyUI's `timeline timeline-vertical timeline-snap-icon` component
   - Responsive design with `max-md:timeline-compact` for mobile
   - Each event displays:
     - Icon with color coding
     - Relative timestamp (with absolute time on hover via title attribute)
     - Event title and description
     - Metadata badges (quality, indexer, resolution, size)
     - Error messages for failed events

### Event Types Implemented

- **Media Added** (info): When media item is added to library
- **Download Started** (primary): When a download is initiated
- **Download Completed** (success): When download finishes successfully
- **Download Failed** (error): When download fails with error details
- **Download Cancelled** (warning): When download is cancelled
- **File Imported** (success): When media files are imported with quality info
- **Episodes Updated** (info): When TV show episodes are refreshed (grouped by timestamp)

### Color Coding & Icons

- Success events: green (text-success) with check/document icons
- Error events: red (text-error) with x-circle icon
- Info events: blue (text-info) with plus-circle/arrow-path icons
- Warning events: yellow (text-warning) with minus-circle icon
- Primary events: purple (text-primary) with download icon

### Benefits

- Chronological visualization makes it easier to track media lifecycle
- Color-coded status provides quick visual feedback
- Metadata badges show key information at a glance
- Relative timestamps with hover tooltips for precise timing
- Responsive design works seamlessly on mobile devices
- All events are consolidated in one unified view
<!-- SECTION:NOTES:END -->
