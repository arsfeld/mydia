---
id: task-22.10.4
title: Implement MovieSearchJob background worker
status: Done
assignee: []
created_date: '2025-11-05 02:48'
updated_date: '2025-11-05 03:29'
labels:
  - oban
  - jobs
  - movies
  - automation
dependencies:
  - task-22.10.1
  - task-22.10.2
parent_task_id: task-22.10
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create Oban worker that searches for and downloads releases for movies. Supports both background execution (all monitored movies) and UI-triggered execution (specific movie).

## Scope

**Worker: `Mydia.Jobs.MovieSearch`**

Execution modes:
1. `"all_monitored"` - Search all monitored movies without files (cron)
2. `"specific"` - Search single movie by ID (UI-triggered)

For each movie:
- Build search query from title and year
- Search all indexers
- Rank results using ReleaseRanker
- Initiate download for best result
- Log decisions and outcomes

## Implementation

**Job configuration:**
- Queue: `:search`
- Max attempts: 3
- Unique: true (prevent duplicate concurrent searches)

**Query construction:**
- Extract title and year from movie metadata
- Format: "{title} {year}"
- Example: "The Matrix 1999"

**Flow:**
1. Load movie(s) based on mode
2. Filter to only movies without media_files (if all_monitored)
3. For each movie:
   - Build query from title/year
   - Call `Indexers.search_all(query, min_seeders: 5)`
   - Build ranking options from movie/config
   - Call `ReleaseRanker.select_best_result(results, opts)`
   - If match found, call `Downloads.initiate_download(result, media_item_id: movie.id)`
   - Log outcome (found/not found, download initiated, etc.)

**Logging:**
- Info: Search started, results found, download initiated
- Warning: No results, no suitable results
- Error: Indexer failures, download failures

**Error handling:**
- Continue processing other movies if one fails
- Return `:ok` even if some movies fail (logged)
- Only return `{:error, reason}` for fatal errors

## Testing

- Test all_monitored mode with multiple movies
- Test specific mode with single movie
- Test with movie that has no results
- Test with movie that has unsuitable results
- Test error handling (indexer failure, download failure)
- Test logging output
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 MovieSearch Oban worker created
- [x] #2 Supports 'all_monitored' mode for background execution
- [x] #3 Supports 'specific' mode for UI-triggered search
- [x] #4 Queries monitored movies without files in all_monitored mode
- [x] #5 Constructs search query from movie title and year
- [x] #6 Uses Indexers.search_all to search across indexers
- [x] #7 Uses ReleaseRanker to select best result
- [x] #8 Initiates download using Downloads.initiate_download
- [x] #9 Logs all search attempts and outcomes
- [x] #10 Handles errors gracefully without stopping
- [x] #11 Skips movies that already have files
- [x] #12 Comprehensive logging for debugging
- [x] #13 Unit and integration tests covering all modes
<!-- AC:END -->
