---
id: task-109.7
title: Add event tracking for background jobs and health checks
status: Done
assignee: []
created_date: '2025-11-06 18:46'
updated_date: '2025-11-06 19:55'
labels:
  - backend
  - integration
  - monitoring
dependencies: []
parent_task_id: task-109
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend event tracking to cover background jobs and health monitoring for complete system visibility.

## Integration Points

**Background Jobs:**
- `Jobs.MetadataRefresh` - Track execution and results
- `Jobs.MovieSearch` - Track automatic searches
- `Jobs.TvShowSearch` - Track automatic searches
- `Jobs.LibraryScanner` - Track scan start/completion
- `Jobs.DownloadMonitor` - Track monitoring cycles

**Health Checks:**
- `Downloads.ClientHealth` - Track health status changes
- `Indexers.Health` - Track indexer status changes

## Implementation Notes

- Add event tracking to Oban worker `perform/1` functions
- Track job.executed with metadata (duration, items_processed)
- Track job.failed with error details
- Track health status changes with previous/new status
- Use :job actor_type for job events
- Use :system actor_type for health events
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Job execution events created for all background jobs
- [ ] #2 Job failure events created with error details
- [ ] #3 Health status change events created for download clients
- [ ] #4 Health status change events created for indexers
- [ ] #5 Events include relevant metadata (duration, status, errors)
- [ ] #6 Events don't cause job failures
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Add event tracking to Oban worker `perform/1` functions
- Track job.executed with metadata (duration, items_processed)
- Track job.failed with error details
- Track health status changes with previous/new status
- Use :job actor_type for job events
- Use :system actor_type for health events
<!-- SECTION:DESCRIPTION:END -->

Implementation completed: Added job execution and failure event tracking to all background jobs (MetadataRefresh, MovieSearch, TVShowSearch all 5 modes, LibraryScanner, DownloadMonitor). Events include duration_ms, items_processed, and job-specific metadata. Note: Health check tracking was not implemented as ClientHealth and Indexers.Health modules don't exist in codebase yet.
<!-- SECTION:NOTES:END -->
