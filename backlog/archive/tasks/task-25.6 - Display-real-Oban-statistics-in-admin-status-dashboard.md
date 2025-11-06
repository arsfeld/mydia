---
id: task-25.6
title: Display real Oban statistics in admin status dashboard
status: Done
assignee: []
created_date: '2025-11-04 15:49'
updated_date: '2025-11-06 03:38'
labels:
  - ui
  - monitoring
  - oban
  - admin
dependencies:
  - task-24
parent_task_id: task-25
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fix the admin status dashboard to show real Oban job statistics instead of hardcoded zeros. Currently at lib/mydia_web/live/admin_status_live/index.ex:131-148, the get_oban_stats/0 function just returns hardcoded values:

```elixir
%{
  running_jobs: 0,
  queued_jobs: 0,
  queues: []
}
```

This is separate from task-24 which created a dedicated jobs monitoring UI at /admin/jobs. The admin status dashboard at /admin/status should show a summary/overview of the Oban system health including counts of running and queued jobs.

The status dashboard should provide a quick glance at system health, while the dedicated jobs UI provides detailed job history and management.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 get_oban_stats/0 queries actual Oban queue states instead of returning zeros
- [x] #2 Running jobs count reflects jobs currently executing
- [x] #3 Queued jobs count reflects jobs waiting to execute across all queues
- [x] #4 Queue list shows each configured queue with its status
- [x] #5 Stats update in real-time using LiveView
- [x] #6 Gracefully handles Oban not being available (dev/test environments)
- [x] #7 Performance is acceptable (stats retrieval is fast, uses caching if needed)
- [x] #8 UI clearly distinguishes between healthy (jobs processing) and unhealthy (stuck queues) states
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully replaced hardcoded Oban statistics with real-time data from the Oban system.

### Changes Made

**1. Updated `get_oban_stats/0` function** (`lib/mydia_web/live/admin_status_live/index.ex:131-179`):
- Now queries actual Oban queue states using `Oban.check_queue/1`
- Retrieves running and available job counts for each configured queue
- Calculates totals across all queues
- Returns queue details including name, running count, available count, and paused status
- Gracefully handles Oban not being available with error messages

**2. Enhanced UI template** (`lib/mydia_web/live/admin_status_live/index.html.heex:269-366`):
- Added overall system health badge (Active/Idle) based on job activity
- Added descriptive text for running/queued job stats
- Added new "Queue Status" section with detailed queue information table
- Color-coded queue status badges:
  - Red (badge-error): Paused queues
  - Green (badge-success): Processing queues
  - Yellow (badge-warning): Pending queues
  - Gray (badge-ghost): Idle queues
- Running/available counts highlighted with appropriate badge colors

**3. Added tests** (`test/mydia_web/live/admin_status_live_test.exs`):
- Authentication and authorization tests
- Content display tests
- Verified Oban unavailable message in test environment

### Technical Details

The implementation uses Oban's built-in `Oban.check_queue/1` API which provides:
- `running`: Count of currently executing jobs
- `available`: Count of jobs waiting to execute
- `paused`: Boolean indicating if the queue is paused

The stats update automatically every 5 seconds via the existing LiveView refresh mechanism, providing real-time monitoring without additional overhead.

### Performance

- Uses lightweight Oban API calls (no database queries needed)
- Minimal overhead - just iterating over configured queues
- Fast enough for 5-second refresh interval
- No caching needed due to low computational cost
<!-- SECTION:NOTES:END -->
