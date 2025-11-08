---
id: task-105
title: Investigate background search adding torrents for unmonitored series
status: Done
assignee: []
created_date: '2025-11-06 17:42'
updated_date: '2025-11-06 17:57'
labels:
  - bug
  - investigation
  - background-search
  - monitoring
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The background search functionality appears to be adding torrents for series that are not being monitored. This needs investigation to understand why unmonitored series are being processed.

**Investigation areas:**
- Check Docker database to see which series are marked as monitored vs unmonitored
- Review logs to identify when/how torrents are being added for unmonitored series
- Examine the background search logic to identify the bug
- Determine if this is a filtering issue or a monitoring state issue
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Identify the root cause of torrents being added for unmonitored series
- [x] #2 Document findings from database and log analysis
- [x] #3 Create follow-up tasks for any fixes needed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Investigation Findings

### Root Cause Identified

The background search is adding torrents for unmonitored TV shows because the `load_monitored_episodes_without_files` function in `lib/mydia/jobs/tv_show_search.ex:225` only checks if individual **episodes** are monitored, but does NOT check if the parent **media_item (TV show)** is also monitored.

### Evidence

1. **Database Analysis:**
   - 14 TV shows total in database
   - Only 1 monitored: "The Witcher"
   - 13 unmonitored shows including: Friends, Yellowstone, The Last of Us, House of the Dragon, etc.
   - Found many episodes marked as `monitored: true` for shows marked as `monitored: false`

2. **Downloads Analysis:**
   - Multiple downloads found for unmonitored shows:
     - Friends (unmonitored): 10 downloads
     - Yellowstone (unmonitored): 5 downloads
     - The Last of Us (unmonitored): 1+ downloads
   - All downloads created on 2025-11-06 around 16:48-49

3. **Logs Analysis:**
   - Confirmed searches were performed for ALL shows including unmonitored ones
   - Prowlarr logs show searches for: Friends, Yellowstone, The Last of Us, House of the Dragon, Severance, Stranger Things, etc.

### Bug Location

**File:** `lib/mydia/jobs/tv_show_search.ex`
**Function:** `load_monitored_episodes_without_files` (line 225)

**Current Code (Buggy):**
```elixir
defp load_monitored_episodes_without_files do
  today = Date.utc_today()

  Episode
  |> where([e], e.monitored == true)  # ❌ Only checks episode monitoring
  |> where([e], e.air_date <= ^today)
  |> join(:left, [e], mf in assoc(e, :media_files))
  |> group_by([e], e.id)
  |> having([e, mf], count(mf.id) == 0)
  |> preload(:media_item)
  |> Repo.all()
end
```

**Issue:** The query only filters by `e.monitored == true` (episode monitoring) but doesn't check if the parent media_item is also monitored.

### Proposed Fix

Add a join to media_item and check both episode AND show monitoring status:

```elixir
defp load_monitored_episodes_without_files do
  today = Date.utc_today()

  Episode
  |> join(:inner, [e], m in assoc(e, :media_item))  # ✅ Add join
  |> where([e, m], e.monitored == true and m.monitored == true)  # ✅ Check both
  |> where([e], e.air_date <= ^today)
  |> join(:left, [e], mf in assoc(e, :media_files))
  |> group_by([e], e.id)
  |> having([e, mf], count(mf.id) == 0)
  |> preload(:media_item)
  |> Repo.all()
end
```

### Additional Functions to Check

The same bug likely exists in related functions:
- `load_episodes_for_show` (line 238)
- `load_episodes_for_season` (line 252)

Both should also verify the parent media_item is monitored.
<!-- SECTION:NOTES:END -->
