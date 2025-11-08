---
id: task-109.9
title: Migrate media item history timeline to use Events system
status: Done
assignee: []
created_date: '2025-11-06 19:47'
updated_date: '2025-11-06 19:56'
labels:
  - enhancement
  - backend
  - ui
  - refactoring
dependencies:
  - task-109.3
parent_task_id: task-109
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current `build_timeline_events/2` function in MediaLive.Show with the Events system for displaying media item history.

## Current Implementation Issues

The current timeline at `lib/mydia_web/live/media_live/show.ex:1360-1496`:
- Reconstructs history from database records on every page load (136 lines)
- Loses context about who triggered actions (user vs system vs job)
- Can't capture events that don't leave database traces
- Duplicates logic across the codebase

## Implementation Tasks

1. Add missing event types to Events context:
   - `file_imported/3` for media file imports
   - `episodes_refreshed/4` for TV show metadata refreshes

2. Replace `build_timeline_events/2` with `Events.get_resource_events("media_item", id, limit: 50)`

3. Update timeline template (`show.html.heex:526-610`) to use Event structs:
   - Map event types to icons/colors
   - Format event metadata for display
   - Keep existing timeline UI design

4. Subscribe to PubSub events for real-time updates:
   - Already available via `events:all` topic
   - Add handler for `{:event_created, event}` messages

5. Test timeline displays correctly with Events data

## Benefits

- Simpler code (replace 136 lines with single query)
- Rich actor context (user/system/job attribution)
- Real-time updates via existing PubSub
- Consistent event tracking across application
- Foundation for per-resource activity feeds

## Parent Task

task-109
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Media item history timeline displays events from Events system
- [x] #2 Missing event types (file_imported, episodes_refreshed) are added
- [x] #3 Timeline updates in real-time via PubSub
- [x] #4 All existing timeline events are preserved (no functionality loss)
- [x] #5 build_timeline_events/2 function is removed
- [x] #6 Timeline UI/UX remains unchanged from user perspective
<!-- AC:END -->
