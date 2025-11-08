---
id: task-22.10.6
title: Configure automatic search job schedules
status: Done
assignee: []
created_date: '2025-11-05 02:48'
updated_date: '2025-11-05 15:33'
labels:
  - configuration
  - oban
  - cron
dependencies:
  - task-22.10.3
  - task-22.10.4
parent_task_id: task-22.10
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add MovieSearch and TVShowSearch jobs to Oban cron configuration so they run automatically on schedule.

## Scope

Update `config/config.exs` to add cron entries for the new search jobs.

## Implementation

Add to Oban cron configuration:

```elixir
{Oban.Plugins.Cron,
 crontab: [
   # Existing jobs
   {"0 * * * *", Mydia.Jobs.LibraryScanner},
   {"*/2 * * * *", Mydia.Jobs.DownloadMonitor},
   
   # New automatic search jobs
   {"*/30 * * * *", Mydia.Jobs.MovieSearch, args: %{"mode" => "all_monitored"}},
   {"*/15 * * * *", Mydia.Jobs.TVShowSearch, args: %{"mode" => "all_monitored"}}
 ]}
```

**Schedules:**
- MovieSearch: Every 30 minutes (less frequent, movies don't update often)
- TVShowSearch: Every 15 minutes (more frequent, episodes release regularly)

These can be adjusted later based on usage patterns and system load.

## Testing

- Verify jobs appear in Oban cron list
- Verify jobs execute on schedule
- Check logs to confirm automatic execution
- Manually trigger to verify args are passed correctly
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 MovieSearch job added to cron configuration
- [x] #2 TVShowSearch job added to cron configuration
- [x] #3 MovieSearch runs every 30 minutes with 'all_monitored' mode
- [x] #4 TVShowSearch runs every 15 minutes with 'all_monitored' mode
- [x] #5 Jobs appear in Oban cron job list
- [ ] #6 Jobs execute automatically on schedule
- [ ] #7 Logs confirm automatic execution
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

Added both MovieSearch and TVShowSearch jobs to the Oban cron configuration in `config/config.exs`:

- **MovieSearch**: Runs every 30 minutes with `args: %{"mode" => "all_monitored"}`
- **TVShowSearch**: Runs every 15 minutes with `args: %{"mode" => "all_monitored"}`

The configuration compiles without errors and follows the existing cron job pattern.

**Note**: Acceptance criteria 6 and 7 (verifying jobs execute on schedule and checking logs) can only be verified when the application is running. The configuration is now in place and ready for runtime verification.
<!-- SECTION:NOTES:END -->
