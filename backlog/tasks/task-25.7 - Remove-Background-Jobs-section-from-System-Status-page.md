---
id: task-25.7
title: Remove Background Jobs section from System Status page
status: Done
assignee: []
created_date: '2025-11-06 04:38'
updated_date: '2025-11-06 04:46'
labels:
  - ui
  - cleanup
  - admin
  - refactoring
dependencies:
  - task-25.6
parent_task_id: task-25
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The System Status page at `/admin/status` currently displays a Background Jobs section showing Oban statistics. However, there is already a dedicated Background Jobs page at `/admin/jobs` (created in task-24) that provides detailed job monitoring and management.

Having the Background Jobs section on the status page is redundant and clutters the system overview. The status page should focus on high-level system health metrics (database, configuration, library paths, etc.) while job monitoring should be handled by the dedicated jobs page.

**Current location**: `lib/mydia_web/live/admin_status_live/index.html.heex:269-366`

**Related tasks**:
- task-24: Created dedicated jobs monitoring UI at /admin/jobs
- task-25.6: Added real Oban statistics to status page (now needs to be removed)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Background Jobs section removed from /admin/status page template
- [x] #2 get_oban_stats/0 function removed from AdminStatusLive.Index module
- [x] #3 oban_stats assign removed from load_system_data/1
- [x] #4 Status page still displays other system information (database, config, etc.)
- [x] #5 No broken links or references to removed section
- [x] #6 Tests updated to remove Background Jobs assertions
<!-- AC:END -->
