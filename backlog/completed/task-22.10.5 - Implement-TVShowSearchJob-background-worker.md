---
id: task-22.10.5
title: Implement TVShowSearchJob background worker
status: Done
assignee:
  - Claude
created_date: '2025-11-05 02:48'
updated_date: '2025-11-05 15:24'
labels:
  - oban
  - jobs
  - tv
  - automation
dependencies:
  - task-22.10.1
  - task-22.10.2
parent_task_id: task-22.10
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create Oban worker that searches for and downloads releases for TV show episodes. Supports background execution (all monitored episodes) and UI-triggered execution (specific episode or all episodes for a show).

## Scope

**Worker: `Mydia.Jobs.TVShowSearch`**

Execution modes:
1. `"all_monitored"` - Search all missing monitored episodes (cron)
2. `"specific"` - Search single episode by ID (UI-triggered)
3. `"show"` - Search all missing episodes for a show (UI-triggered)

For each episode:
- Build search query from show title, season, episode numbers
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
- Extract show title, season number, episode number
- Format: "{show_title} S{season:02d}E{episode:02d}"
- Example: "Breaking Bad S01E03"

**Episode filtering (all_monitored mode):**
- Episodes where monitored = true
- Episodes without media_files
- Episodes with air_date in the past (already aired)
- Skip episodes with air_date in future

**Flow:**
1. Load episode(s) based on mode
2. For each episode:
   - Check if already has files (skip if so)
   - Check if aired (skip if future)
   - Build query from show/season/episode
   - Call `Indexers.search_all(query, min_seeders: 3)`
   - Build ranking options
   - Call `ReleaseRanker.select_best_result(results, opts)`
   - If match found, call `Downloads.initiate_download(result, episode_id: episode.id, media_item_id: show.id)`
   - Log outcome

**Logging:**
- Info: Search started, results found, download initiated
- Debug: Episode skipped (future air date, already has files)
- Warning: No results, no suitable results
- Error: Indexer failures, download failures

## Testing

- Test all_monitored mode with multiple episodes
- Test specific mode with single episode
- Test show mode with all episodes for a show
- Test filtering (skip future episodes, skip episodes with files)
- Test query construction with various formats
- Test error handling
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 TVShowSearch Oban worker created
- [x] #2 Supports 'all_monitored' mode for background execution
- [x] #3 Supports 'specific' mode for UI-triggered episode search
- [x] #4 Supports 'show' mode for searching all episodes of a show
- [x] #5 Queries monitored episodes without files that have aired
- [x] #6 Skips episodes with future air dates
- [x] #7 Constructs search query from show title and S##E## format
- [x] #8 Uses Indexers.search_all to search across indexers
- [x] #9 Uses ReleaseRanker to select best result
- [x] #10 Initiates download using Downloads.initiate_download
- [x] #11 Associates download with both episode_id and media_item_id
- [x] #12 Logs all search attempts and outcomes
- [x] #13 Handles errors gracefully without stopping
- [x] #14 Comprehensive tests covering all modes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan - Approved

### Overview
Create `lib/mydia/jobs/tv_show_search.ex` with intelligent season pack support. The job will support 4 execution modes with different season pack strategies based on use case.

### Execution Modes

1. **`"specific"`** - Single episode (UI: "Search Episode" button)
   - Only search for individual episode
   - No season pack consideration
   - Args: `%{"mode" => "specific", "episode_id" => id}`

2. **`"season"`** - Full season (UI: "Download Season" button)
   - ALWAYS prefer season pack
   - Search for season pack first
   - Only fall back to individual episodes if no season pack found
   - Args: `%{"mode" => "season", "media_item_id" => id, "season_number" => num}`

3. **`"show"`** - All episodes for a show (UI: "Auto Search Show" button)
   - Use smart decision logic per season (70% threshold)
   - Args: `%{"mode" => "show", "media_item_id" => id}`

4. **`"all_monitored"`** - Background cron job
   - Use smart decision logic per season (70% threshold)
   - Args: `%{"mode" => "all_monitored"}`

### Smart Season Pack Decision Logic

For "all_monitored" and "show" modes, group episodes by season and apply:

```
For each season group:
  missing_count = episodes without files
  total_count = total episodes in season (from metadata or DB)
  
  if missing_count == 0:
    skip
  
  missing_percentage = (missing_count / total_count) * 100
  
  if missing_percentage >= 70:
    # Most of season missing - prefer season pack
    season_pack_result = search_season_pack()
    if season_pack_result:
      download_season_pack()
    else:
      download_individual_episodes()
  else:
    # Only a few episodes missing - just get those
    download_individual_episodes()
```

Threshold: Hardcode 70% for now, can be made configurable later.

### Query Construction

**Individual Episode:**
- Format: `"{show_title} S{season:02d}E{episode:02d}"`
- Example: `"Breaking Bad S01E03"`
- Function: `build_episode_query/1`

**Season Pack:**
- Format: `"{show_title} S{season:02d}"`
- Example: `"Breaking Bad S01"`
- Function: `build_season_query/2`

### Key Functions

**Query Functions:**
- `load_monitored_episodes_without_files/0` - All monitored episodes without files, aired only
- `load_episode/1` - Single episode by ID, preload media_item
- `load_episodes_for_show/1` - All missing episodes for one show
- `load_episodes_for_season/2` - All missing episodes for show + season (for "season" mode)

**Search Functions:**
- `search_episode/2` - Search for individual episode
- `search_season_pack/2` - Search for season pack (S## format)
- `search_individual_episodes/2` - Search multiple episodes individually

**Decision Functions:**
- `process_episodes/2` - Main coordinator, groups by season, applies logic
- `should_prefer_season_pack?/2` - Calculates missing percentage, returns true if >= 70%
- `choose_best_option/3` - Compares season pack vs individual episode results

**Download Functions:**
- `initiate_episode_download/2` - Single episode download
- `initiate_season_pack_download/3` - Season pack download (multiple episodes)

### Download Association Strategy

**Simple approach (MVP):**
Create one Download record for season pack:
- Pass `media_item_id` only (not episode_id)
- Store season info in metadata: `%{season_pack: true, season_number: 1}`
- Import job will match files to episodes later

**Future enhancement:**
Update `Downloads.initiate_download/2` to accept `episode_ids: [...]` for proper multi-episode association.

### Season Pack Detection

Validate season pack results:
- Title contains season marker (S01, S02, etc.)
- Title does NOT contain episode marker (E01, E02)
- Size is reasonable for full season (> 2GB for HD)
- Can use ReleaseRanker metadata or add validation step

### File Structure

**Main file:** `lib/mydia/jobs/tv_show_search.ex`
**Tests:** `test/mydia/jobs/tv_show_search_test.exs`

### Oban Configuration

```elixir
use Oban.Worker,
  queue: :search,
  max_attempts: 3,
  unique: [period: 60, fields: [:args]]
```

### Episode Filtering

For all modes:
- Only monitored episodes (`monitored == true`)
- Only aired episodes (`air_date <= today`)
- Only episodes without files (left join media_files, count == 0)
- Preload media_item (need show title)

### Logging Strategy

- Info: Mode started, episodes found, season groups, season pack vs episodes decision, download initiated
- Debug: Episode skipped (has files, future), season pack detection
- Warning: No results, no suitable results, season pack incomplete
- Error: Failed to load episode/show, indexer failures, download failures
- Summary: Total/successful/failed/no_results/season_packs_downloaded counts

### Error Handling

- Rescue `Ecto.NoResultsError` for missing episodes/shows
- Continue processing other episodes if one fails
- Return `:ok` for successful batch
- Individual failures logged but don't stop job

### Implementation Phases

**Phase 1: Basic Episode Search**
- Implement "specific" mode with individual episode search
- Query functions and episode filtering
- Basic search and download flow
- Tests for single episode

**Phase 2: Season Pack Support**
- Implement "season" mode (always prefer season pack)
- Season pack search and detection
- Season pack download with metadata
- Tests for season mode

**Phase 3: Smart Decision Logic**
- Implement "show" and "all_monitored" modes
- Episode grouping by season
- 70% threshold decision logic
- Tests for smart selection

**Phase 4: Integration**
- Update UI to trigger all 4 modes
- Integration tests
- Documentation

### Dependencies

- ✅ `ReleaseRanker.select_best_result/2` (task-22.10.2)
- ✅ `Downloads.initiate_download/2` exists, supports episode_id
- ✅ `Indexers.search_all/2` available
- ✅ Episode schema has needed fields
- ⚠️ May need small update to Downloads for season pack metadata

### Open Questions / Future Enhancements

- Make 70% threshold configurable
- Support for `episode_ids` (plural) in Downloads context
- Season pack quality comparison (if season pack is lower quality than some episodes)
- Partial season handling (download season pack but already have some episodes)
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Phase 1 Complete (Specific Mode)

**Completed:**
- Created TVShowSearch Oban worker with basic structure
- Implemented 'specific' mode for single episode searches
- Query construction with S##E## format (e.g., 'Breaking Bad S01E03')
- Episode filtering (skips future episodes and episodes with files)
- Integration with Indexers.search_all and ReleaseRanker
- Download initiation with Downloads.initiate_download
- Comprehensive test suite with 9 passing tests
- Proper error handling for missing episodes and unsupported modes

**Key Implementation Details:**
- Returns :ok for all successful operations (including no results found)
- Properly preloads media_item association for query construction
- Uses correct Oban return values per specification
- Quality profile support for ranking preferences
- Size range defaults to 100-5000 MB for TV episodes
- Min seeders defaults to 3 for TV content

## Phase 2 Complete (Season Mode)

**Completed:**
- Implemented 'season' mode for UI-triggered season pack downloads
- Season pack search with fallback to individual episodes
- Season pack filtering (must contain S## marker, no E## markers)
- Intelligent fallback logic when season pack not found or unsuitable
- Season pack download with metadata tracking (season_number, episode_ids)
- Adjusted size ranges for season packs (2-100GB vs 100-5000MB for episodes)
- Quality profile support for season-level ranking
- Individual episode search as fallback for season mode
- Comprehensive error handling for missing shows and invalid types
- 5 additional passing tests for season mode (14 total)

**Key Implementation Details:**
- Season packs identified by presence of S## and absence of E## in title
- Season pack metadata stored in result for import job matching
- Downloads linked to media_item_id (not episode_id) for season packs
- Sequential fallback: try season pack → filter invalid → rank → fallback to episodes
- Logging at each decision point for debugging and monitoring

## Phase 3 Complete (Show and All_Monitored Modes)

**Completed:**
- Implemented 'show' mode for UI-triggered full show searches
- Implemented 'all_monitored' mode for scheduled background execution
- Smart season pack logic with 70% threshold calculation
- Episode grouping by season for intelligent decision making
- Metadata-based episode count retrieval with fallback logic
- Processes multiple shows in all_monitored mode efficiently
- Season-by-season independent processing
- Comprehensive logging at all decision points
- Error handling for missing shows and invalid types
- 10 additional passing tests (24 total covering all 4 modes)

**Key Implementation Details:**
- Groups episodes by show, then by season for processing
- Calculates missing_percentage = (missing_count / total_count) * 100
- Prefers season pack when missing_percentage >= 70%
- Falls back to individual episodes when < 70%
- Retrieves total episode count from media_item metadata
- Fallback: assumes all known episodes are the total if metadata missing
- Each season processed independently with own threshold check
- all_monitored mode groups by media_item_id for efficiency
- Logs threshold calculations at debug level for troubleshooting

## Task Complete ✓

**Final Status:**
- All 14 acceptance criteria met
- 24 comprehensive tests passing
- 4 execution modes fully implemented and tested
- ~700 lines of production code + ~500 lines of test code
- Compilation successful (no errors)
- All phases completed according to implementation plan

**Files Created:**
- `lib/mydia/jobs/tv_show_search.ex` (TVShowSearch Oban worker)
- `test/mydia/jobs/tv_show_search_test.exs` (comprehensive test suite)

**Ready for:**
- Phase 4 UI integration (separate task)
- Scheduled cron job configuration
- Production deployment

**Notable Features:**
- Intelligent season pack vs individual episode decision making
- Robust error handling and logging throughout
- Efficient batch processing for all_monitored mode
- Quality profile integration for ranking
- Metadata-based episode count with fallback logic
- Season pack detection with regex filtering
<!-- SECTION:NOTES:END -->
