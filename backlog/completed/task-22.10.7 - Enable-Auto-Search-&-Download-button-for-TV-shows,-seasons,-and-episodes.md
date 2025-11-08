---
id: task-22.10.7
title: 'Enable Auto Search & Download button for TV shows, seasons, and episodes'
status: Done
assignee: []
created_date: '2025-11-05 15:33'
updated_date: '2025-11-05 15:39'
labels:
  - ui
  - liveview
  - tv-shows
  - automation
dependencies:
  - task-22.10.1
  - task-22.10.5
parent_task_id: '22.10'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Complete the TV show integration for the "Auto Search & Download" button that was left as a placeholder in task-22.10.1. Now that TVShowSearchJob is implemented (task-22.10.5), update the media detail page UI to support automatic search and download for TV shows, seasons, and individual episodes.

## Background

Task-22.10.1 implemented the "Auto Search & Download" button for movies but left TV show support as a placeholder with "not yet implemented" message. The implementation note stated: "TV show support placeholder added (awaiting task-22.10.5)".

Now that task-22.10.5 is complete with all 4 TVShowSearch modes working, we need to wire up the UI to use these modes.

## Scope

**Files to Update:**
- `lib/mydia_web/live/media_live/show.ex` - LiveView module
- `lib/mydia_web/live/media_live/show.html.heex` - Template (if needed)

**UI Integration Points:**

1. **TV Show (entire series)**
   - Button on show detail page
   - Queue: `TVShowSearch.new(%{"mode" => "show", "media_item_id" => id})`
   - Searches all missing episodes across all seasons with smart logic

2. **Season**
   - Button on season section/detail
   - Queue: `TVShowSearch.new(%{"mode" => "season", "media_item_id" => id, "season_number" => num})`
   - Always prefers season pack with fallback to individual episodes

3. **Individual Episode**
   - Button on episode row/detail
   - Queue: `TVShowSearch.new(%{"mode" => "specific", "episode_id" => id})`
   - Searches for single episode only

## Implementation Details

**1. Update `auto_search_download` event handler:**
```elixir
def handle_event("auto_search_download", _params, socket) do
  media_item = socket.assigns.media_item
  
  case media_item.type do
    "movie" ->
      # Existing movie logic
      
    "tv_show" ->
      # Queue TVShowSearch with mode "show"
      %{mode: "show", media_item_id: media_item.id}
      |> Mydia.Jobs.TVShowSearch.new()
      |> Oban.insert()
      
      {:noreply,
       socket
       |> assign(:auto_searching, true)
       |> put_flash(:info, "Searching for all missing episodes of #{media_item.title}...")
       |> schedule_auto_search_timeout()}
  end
end
```

**2. Add episode-specific event handler:**
```elixir
def handle_event("auto_search_episode", %{"episode-id" => episode_id}, socket) do
  # Load episode to get details for flash message
  episode = Media.get_episode!(episode_id)
  
  %{mode: "specific", episode_id: episode_id}
  |> Mydia.Jobs.TVShowSearch.new()
  |> Oban.insert()
  
  {:noreply,
   socket
   |> assign(:auto_searching_episode, episode_id)
   |> put_flash(:info, "Searching for S#{episode.season_number}E#{episode.episode_number}...")
   |> schedule_auto_search_timeout()}
end
```

**3. Add season-specific event handler:**
```elixir
def handle_event("auto_search_season", %{"season-number" => season_number}, socket) do
  media_item = socket.assigns.media_item
  season_num = String.to_integer(season_number)
  
  %{mode: "season", media_item_id: media_item.id, season_number: season_num}
  |> Mydia.Jobs.TVShowSearch.new()
  |> Oban.insert()
  
  {:noreply,
   socket
   |> assign(:auto_searching_season, season_num)
   |> put_flash(:info, "Searching for season #{season_num} (preferring season pack)...")
   |> schedule_auto_search_timeout()}
end
```

**4. Update prerequisite check:**
```elixir
defp can_auto_search?(%Media.MediaItem{type: "tv_show"} = media_item, _downloads) do
  # TV shows might not need quality profile if episodes have their own
  # For now, use same logic as movies
  not is_nil(media_item.quality_profile_id)
end
```

**5. Handle PubSub events for TV downloads:**
- Downloads for TV shows can be associated with episodes or media_items
- Need to handle both cases in `handle_info({:download_created, download})`
- Match against `auto_searching`, `auto_searching_episode`, or `auto_searching_season` state

**6. Update button visibility:**
- Show button for TV shows (currently hidden/disabled)
- Add buttons for seasons (in season sections)
- Add buttons for episodes (in episode lists/cards)

**7. User feedback messages:**
- TV show: "Searching for all missing episodes of {title}..."
- Season: "Searching for season {num} (preferring season pack)..."
- Episode: "Searching for S{season}E{episode}..."
- Success: Show episode/season info in download started message
- Timeout: "Search completed but no suitable releases found for..."

## UI/UX Considerations

- **TV Show button**: Same location as movie button
- **Season button**: In season header or actions area
- **Episode button**: In episode row actions (next to status badge)
- **Loading states**: Track separately for show/season/episode searches
- **Disabled states**: Check prerequisites per context (show vs episode)

## Testing

- Test TV show auto search with multiple seasons
- Test season auto search (verify season pack preference)
- Test episode auto search
- Test error cases (no quality profile, no download clients)
- Test timeout handling when no results
- Test success feedback with download details
- Test that multiple concurrent searches work (e.g., multiple episodes)

## Dependencies

- ✅ task-22.10.5 (TVShowSearch job) - Complete
- ✅ task-22.10.1 (Movie UI) - Complete, provides pattern to follow
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Auto Search & Download button works for TV shows (entire series)
- [x] #2 Button queues TVShowSearch job with mode 'show' and correct media_item_id
- [x] #3 Auto search button/action added for seasons
- [x] #4 Season search queues job with mode 'season' and correct parameters
- [x] #5 Auto search button/action added for individual episodes
- [x] #6 Episode search queues job with mode 'specific' and correct episode_id
- [x] #7 Loading states track separately for show/season/episode searches
- [x] #8 Success messages show appropriate context (episode/season info)
- [x] #9 Prerequisite checks updated for TV shows
- [x] #10 PubSub event handling works for TV show downloads
- [x] #11 Button disabled when prerequisites not met
- [x] #12 Timeout handling shows appropriate 'no results' message
- [x] #13 Multiple concurrent episode searches supported
- [x] #14 All three contexts tested (show, season, episode)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully implemented Auto Search & Download functionality for TV shows, seasons, and individual episodes.

### Changes Made

**1. LiveView Module (`lib/mydia_web/live/media_live/show.ex`)**

- **Added state tracking**: Added `auto_searching_season` and `auto_searching_episode` assigns to track separate auto search states
- **Updated `auto_search_download` event**: Replaced TV show placeholder with actual TVShowSearchJob queuing using mode "show"
- **Added `auto_search_season` event**: Queues TVShowSearchJob with mode "season" and season_number parameter
- **Added `auto_search_episode` event**: Queues TVShowSearchJob with mode "specific" and episode_id parameter
- **Enhanced PubSub handling**: Updated `handle_info({:download_created, download})` to detect and show success messages for all three search types (show/season/episode)
- **Added timeout handlers**: 
  - `auto_search_season_timeout` for season searches
  - `auto_search_episode_timeout` for episode searches
- **Updated `can_auto_search?/2`**: Changed supported types from `["movie"]` to `["movie", "tv_show"]`
- **Added `episode_in_season?/2` helper**: Checks if an episode belongs to a specific season

**2. Template (`lib/mydia_web/live/media_live/show.html.heex`)**

- **Season-level action**: Added "Auto Search Season" button with loading state indicator
- **Episode-level action**: Added auto search button (bolt icon) for individual episodes with loading spinner
- **Reordered episode buttons**: Auto search first, then manual search, then monitor toggle

### User Experience

- **TV Show button**: Searches for all missing episodes across all seasons
- **Season button**: Searches for season pack with fallback to individual episodes
- **Episode button**: Searches for specific episode only
- **Loading states**: Each context shows appropriate loading spinner during search
- **Success feedback**: Shows download title when match is found
- **Timeout handling**: Shows appropriate "no results" message after 30 seconds if no download initiated

### Technical Details

- All three search modes use the TVShowSearchJob background worker
- Separate state tracking allows concurrent searches at different levels
- PubSub events properly matched to the correct search context
- Timeout messages provide context-specific feedback

The implementation follows the pattern established for movie auto search and integrates seamlessly with the existing TVShowSearchJob worker from task-22.10.5.
<!-- SECTION:NOTES:END -->
