# Episode Availability Status Indicators - Implementation Guide

## 1. CURRENT EPISODE DISPLAY

### Media Details Page (show.html.heex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/show.html.heex`

**Episode Display Structure:**
- Lines 225-330: Episodes section (TV shows only)
- Episodes grouped by season in collapsible cards
- Table layout with columns: Episode #, Title, Air Date, Quality, Status, Actions
- **Current Status Column (lines 271-286):**
  - Shows monitored/unmonitored status via icon
  - Only displays bookmark icon (monitored or not)
  - No visual indicators for availability (has file, downloading, missing)

**Episode Table Columns:**
- Episode number
- Title
- Air date (hidden on small screens)
- Quality badge (highest resolution file)
- Status (current: just monitored/unmonitored indicator)
- Action buttons (toggle monitored, search)

### LiveView Module (show.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/show.ex`

**Key Functions:**
- `load_media_item(id)` (line 392): Loads media with preloaded data
- `build_preload_list()` (line 398):
  ```elixir
  [
    quality_profile: [],
    episodes: [:media_files, downloads: :media_item],
    media_files: [],
    downloads: []
  ]
  ```
- `get_episode_quality_badge(episode)` (line 552): Gets highest resolution from media_files
- `get_download_status(media_item)` (line 566): Gets active downloads for media item

**Preloading Pattern:**
- Episodes are preloaded with `media_files` and `downloads`
- Downloads include the media_item association
- Allows checking: has files, active downloads

---

## 2. DATA STRUCTURE

### Episode Schema (episode.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia/media/episode.ex`

**Fields:**
```elixir
field :season_number, :integer
field :episode_number, :integer
field :title, :string
field :air_date, :date
field :metadata, :map
field :monitored, :boolean, default: true

# Associations:
has_many :media_files, Mydia.Library.MediaFile
has_many :downloads, Mydia.Downloads.Download
belongs_to :media_item, Mydia.Media.MediaItem
```

### MediaFile Schema (media_file.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia/library/media_file.ex`

**Fields:**
```elixir
field :path, :string
field :size, :integer
field :resolution, :string      # "1080p", "720p", etc.
field :codec, :string
field :hdr_format, :string
field :audio_codec, :string
field :bitrate, :integer
field :verified_at, :utc_datetime

# Relationships:
belongs_to :media_item, Mydia.Media.MediaItem
belongs_to :episode, Mydia.Media.Episode
belongs_to :quality_profile, Mydia.Settings.QualityProfile
```

### Download Schema (download.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia/downloads/download.ex`

**Fields:**
```elixir
field :status, :string          # "pending", "downloading", "completed", "failed", "cancelled"
field :indexer, :string
field :title, :string
field :download_url, :string
field :download_client, :string
field :download_client_id, :string
field :progress, :float         # 0-100
field :estimated_completion, :utc_datetime
field :completed_at, :utc_datetime
field :error_message, :string
field :metadata, :map

# Relationships:
belongs_to :media_item, Mydia.Media.MediaItem
belongs_to :episode, Mydia.Media.Episode
```

### Preloading for Episodes
From `show.ex` line 401:
```elixir
episodes: [:media_files, downloads: :media_item]
```

This provides:
- `episode.media_files` - all files for that episode
- `episode.downloads` - all downloads for that episode
- `episode.downloads[x].media_item` - parent media item

---

## 3. LISTING PAGES

### Media Index Page (index.html.heex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/index.html.heex`

**Two View Modes:**

#### Grid View (lines 144-205)
- 6-column responsive grid
- Card layout with poster image
- Shows: Quality badge (top-right), Monitored indicator (left side)
- **No episode-level availability indicators**
- Selection checkbox for batch operations

#### List View (lines 207-291)
- Table with columns: Checkbox, Poster, Title, Type, Year, Status, Quality, Size, Actions
- Shows: Media-level status (monitored/unmonitored), quality badge
- **No episode-level availability indicators**

**Current Quality Badge:** (line 330-343 in index.ex)
```elixir
defp get_quality_badge(media_item) do
  case media_item.media_files do
    [] -> nil
    files ->
      files
      |> Enum.map(& &1.resolution)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort(:desc)
      |> List.first()
  end
end
```

### Media Index LiveView (index.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/index.ex`

**Preloading Pattern (line 290):**
```elixir
Keyword.put(:preload, [:media_files])
```

Only preloads media_files for display, not episodes or downloads.

---

## 4. CALENDAR VIEW & STATUS COLORS

### Calendar Live (calendar_live/index.ex)
**File:** `/home/arosenfeld/Code/mydia/lib/mydia_web/live/calendar_live/index.ex`

**Status Determination (lines 169-187):**
```elixir
defp get_item_status(item) do
  today = Date.utc_today()

  cond do
    item.has_files -> :downloaded
    Date.compare(item.air_date, today) == :gt -> :upcoming
    item.has_downloads -> :downloading
    true -> :missing
  end
end

defp status_color(status) do
  case status do
    :upcoming -> "bg-base-300 text-base-content/70"     # Gray
    :downloading -> "bg-info text-info-content"         # Blue
    :downloaded -> "bg-success text-success-content"    # Green
    :missing -> "bg-error text-error-content"           # Red
  end
end
```

### Data Provided to Calendar (lines 348-368)
The `list_episodes_by_air_date/2` query includes:
```sql
has_files: CASE WHEN EXISTS(SELECT 1 FROM media_files WHERE episode_id = ?) THEN true ELSE false END
has_downloads: CASE WHEN EXISTS(SELECT 1 FROM downloads WHERE episode_id = ?) THEN true ELSE false END
```

**Status Priority Logic:**
1. Has files → **Downloaded** (green)
2. Air date in future → **Upcoming** (gray)
3. Has downloads → **Downloading** (blue)
4. Otherwise → **Missing** (red)

### Calendar Template (calendar_live/index.html.heex)
**Lines 114-126:** Item color based on status
```heex
class={[
  "w-full text-left text-xs p-1 rounded cursor-pointer hover:opacity-80",
  status_color(get_item_status(item))
]}
```

**Legend (lines 202-222):**
- Gray: Upcoming
- Blue (info): Downloading
- Green (success): Downloaded
- Red (error): Missing

---

## 5. HELPER FUNCTIONS - EXISTING STATUS LOGIC

### In Calendar LiveView (lines 169-187):
```elixir
defp get_item_status(item) do
  today = Date.utc_today()
  cond do
    item.has_files -> :downloaded
    Date.compare(item.air_date, today) == :gt -> :upcoming
    item.has_downloads -> :downloading
    true -> :missing
  end
end

defp status_color(status) do
  case status do
    :upcoming -> "bg-base-300 text-base-content/70"
    :downloading -> "bg-info text-info-content"
    :downloaded -> "bg-success text-success-content"
    :missing -> "bg-error text-error-content"
  end
end
```

### Query Functions in media.ex:
- `list_episodes_by_air_date/3` (line 340): Returns episodes with has_files and has_downloads computed
- `list_movies_by_release_date/3` (line 380): Returns movies with same computed fields

---

## 6. PUBSUB SETUP FOR REAL-TIME UPDATES

### In show.ex (line 11):
```elixir
if connected?(socket) do
  Phoenix.PubSub.subscribe(Mydia.PubSub, "downloads")
end
```

### Handlers (lines 373-388):
```elixir
def handle_info({:download_created, download}, socket) do
  if download_for_media?(download, socket.assigns.media_item) do
    {:noreply, assign(socket, :media_item, load_media_item(socket.assigns.media_item.id))}
  else
    {:noreply, socket}
  end
end

def handle_info({:download_updated, download}, socket) do
  if download_for_media?(download, socket.assigns.media_item) do
    {:noreply, assign(socket, :media_item, load_media_item(socket.assigns.media_item.id))}
  else
    {:noreply, socket}
  end
end
```

**Broadcast Points (in downloads.ex):**
- Line 53: After creating download
- Line 72: After updating download
- Both use `broadcast_download_update(download.id)` (need to check implementation)

---

## 7. RECOMMENDATIONS FOR IMPLEMENTATION

### 1. **Create Helper Module**
Create `/home/arosenfeld/Code/mydia/lib/mydia/media/episode_status.ex` with:

```elixir
defmodule Mydia.Media.EpisodeStatus do
  @doc """
  Determines the availability status of an episode.
  
  Status priority:
  1. Downloaded - has media files
  2. Downloading - has active downloads
  3. Upcoming - air date is in the future
  4. Missing - otherwise
  """
  def get_status(episode, today \\ Date.utc_today()) do
    cond do
      has_files?(episode) -> :downloaded
      has_active_downloads?(episode) -> :downloading
      is_upcoming?(episode, today) -> :upcoming
      true -> :missing
    end
  end
  
  defp has_files?(episode) do
    episode.media_files && Enum.any?(episode.media_files, & &1.path)
  end
  
  defp has_active_downloads?(episode) do
    episode.downloads && 
    Enum.any?(episode.downloads, &(&1.status in ["pending", "downloading"]))
  end
  
  defp is_upcoming?(episode, today) do
    episode.air_date && Date.compare(episode.air_date, today) == :gt
  end
  
  @doc "Returns DaisyUI badge classes for status"
  def status_badge_class(status) do
    case status do
      :downloaded -> "badge-success"
      :downloading -> "badge-info"
      :upcoming -> "badge-ghost"
      :missing -> "badge-error"
    end
  end
  
  @doc "Returns icon name for status"
  def status_icon(status) do
    case status do
      :downloaded -> "hero-check-circle"
      :downloading -> "hero-arrow-down-tray"
      :upcoming -> "hero-calendar"
      :missing -> "hero-exclamation-triangle"
    end
  end
  
  @doc "Returns human-readable status label"
  def status_label(status) do
    case status do
      :downloaded -> "Downloaded"
      :downloading -> "Downloading"
      :upcoming -> "Upcoming"
      :missing -> "Missing"
    end
  end
end
```

### 2. **Update show.ex**
Add to build_preload_list (line 398):
```elixir
defp build_preload_list do
  [
    quality_profile: [],
    episodes: [:media_files, downloads: :media_item],  # already there
    media_files: [],
    downloads: []
  ]
end
```

Add helper function:
```elixir
defp get_episode_status(episode) do
  Mydia.Media.EpisodeStatus.get_status(episode)
end
```

### 3. **Update show.html.heex**
Replace status column (lines 271-286) with:
```heex
<td>
  <% status = get_episode_status(episode) %>
  <div class="flex items-center gap-2">
    <span class={[
      "badge badge-sm",
      Mydia.Media.EpisodeStatus.status_badge_class(status)
    ]}>
      <.icon 
        name={Mydia.Media.EpisodeStatus.status_icon(status)} 
        class="w-3 h-3 mr-1" 
      />
      {Mydia.Media.EpisodeStatus.status_label(status)}
    </span>
  </div>
</td>
```

### 4. **Update index.ex for TV Shows**
If planning to show episode status in listing, need to preload episodes with media_files and downloads:
```elixir
defp build_query_opts(assigns) do
  preload_list =
    case assigns.filter_type do
      "tv_show" -> [:media_files, episodes: [:media_files, :downloads]]
      _ -> [:media_files]
    end
  
  []
  |> maybe_add_filter(:type, assigns.filter_type)
  |> maybe_add_filter(:monitored, assigns.filter_monitored)
  |> Keyword.put(:preload, preload_list)
end
```

### 5. **Calendar Integration**
Already uses same status colors. Can update to use shared module:
```elixir
defp get_item_status(item) do
  if item.type == "episode" do
    # Use episode struct if we create one from the map
    Mydia.Media.EpisodeStatus.get_status(item, @current_date)
  else
    # Movie status logic
    case item do
      %{has_files: true} -> :downloaded
      %{has_downloads: true} -> :downloading
      _ -> :missing
    end
  end
end
```

---

## Summary of Key File Paths

| File | Purpose | Key Function |
|------|---------|--------------|
| `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/show.html.heex` | Episode detail display | Lines 225-330: Episode table |
| `/home/arosenfeld/Code/mydia/lib/mydia_web/live/media_live/show.ex` | Episode LiveView logic | build_preload_list (line 398) |
| `/home/arosenfeld/Code/mydia/lib/mydia/media/episode.ex` | Episode schema | has_many :media_files, :downloads |
| `/home/arosenfeld/Code/mydia/lib/mydia/library/media_file.ex` | File schema | resolution field for quality |
| `/home/arosenfeld/Code/mydia/lib/mydia/downloads/download.ex` | Download schema | status field: pending/downloading/completed/failed |
| `/home/arosenfeld/Code/mydia/lib/mydia_web/live/calendar_live/index.ex` | Calendar with status | get_item_status (line 169), status_color (line 180) |
| `/home/arosenfeld/Code/mydia/lib/mydia_web/live/calendar_live/index.html.heex` | Calendar UI | Status legend (lines 202-222) |
| `/home/arosenfeld/Code/mydia/lib/mydia/media.ex` | Media context | list_episodes_by_air_date (line 340) with has_files/has_downloads |

---

## Status Color Scheme (Confirmed)

- **Gray (bg-base-300):** Upcoming - Episode hasn't aired yet
- **Blue (bg-info):** Downloading - Active downloads in progress
- **Green (bg-success):** Downloaded - Episode has media files
- **Red (bg-error):** Missing - Episode aired but no file or download

This scheme is consistent across calendar and should be applied to details page as well.

---

## APPENDIX: Data Flow Diagram

```
Episode Detail Page Flow:
=======================

User visits /media/:id (TV Show)
        ↓
MediaLive.Show.mount()
        ↓
load_media_item(id)
        ↓
build_preload_list() returns:
  ├── quality_profile: []
  ├── episodes: [:media_files, :downloads]  ← KEY: includes files and downloads
  ├── media_files: []
  └── downloads: []
        ↓
Media.get_media_item!(id, preload: list)
        ↓
Database query with eager loading:
  media_items
    ├── JOIN quality_profiles
    ├── JOIN episodes
    │   ├── JOIN media_files (all files for this episode)
    │   └── JOIN downloads (all downloads for this episode)
    └── JOIN downloads (all downloads for media item)
        ↓
Template render (show.html.heex)
        ↓
For each episode in group_episodes_by_season():
  ├── Episode number
  ├── Title
  ├── Air date
  ├── Quality badge
  ├── Status ← NEEDS: availability indicator
  └── Actions (monitor, search)


Status Determination Logic Flow:
================================

episode.media_files (preloaded) → Check if any have path
                                        ↓
                                    YES → DOWNLOADED (green)
                                    NO  ↓
                                        ↓
episode.air_date → Compare with Date.utc_today()
                        ↓
                    FUTURE → UPCOMING (gray)
                    PAST   ↓
                        ↓
episode.downloads (preloaded) → Check if any status in ["pending", "downloading"]
                                        ↓
                                    YES → DOWNLOADING (blue)
                                    NO  ↓
                                        ↓
                                    MISSING (red)


Real-Time Update Flow:
======================

Download completed
        ↓
Downloads.update_download() broadcasts
        ↓
Phoenix.PubSub publishes to "downloads" topic
        ↓
show.ex handle_info() receives {:download_updated, download}
        ↓
Checks if download belongs to current media_item or its episodes
        ↓
YES → reload_media_item(id) with fresh preloads
        ↓
Template re-renders with updated episode.media_files
        ↓
Status badge updates from DOWNLOADING to DOWNLOADED


Data Structure Summary:
=======================

Episode (with preloads):
{
  id: "...",
  season_number: 1,
  episode_number: 5,
  title: "Episode Title",
  air_date: ~D[2024-11-01],
  monitored: true,
  media_files: [
    {
      id: "...",
      path: "/path/to/file.mkv",
      resolution: "1080p",
      codec: "h264",
      ...
    }
  ],
  downloads: [
    {
      id: "...",
      status: "downloading",
      progress: 45.5,
      title: "Episode Title 1080p",
      ...
    }
  ]
}

Status determines from:
  ✓ media_files[x].path exists → has files
  ✓ downloads[x].status in ["pending", "downloading"] → has active download
  ✓ air_date < today → passed air date
  ✓ air_date > today → upcoming
```

---

## APPENDIX: Implementation Checklist

### Phase 1: Create Shared Status Module
- [ ] Create `/lib/mydia/media/episode_status.ex`
- [ ] Implement `get_status(episode, today)` function
- [ ] Add helper functions for badge class, icon, and label
- [ ] Write tests for status determination logic

### Phase 2: Update Details Page
- [ ] Update `show.ex` to use EpisodeStatus module
- [ ] Modify `show.html.heex` episode table status column
- [ ] Replace bookmark-only indicator with full status badge
- [ ] Test with various episode states (downloaded, downloading, upcoming, missing)

### Phase 3: Real-Time Testing
- [ ] Create/start a download for an episode
- [ ] Verify status updates from "Upcoming" → "Downloading" via PubSub
- [ ] Verify status updates from "Downloading" → "Downloaded" on completion
- [ ] Test status updates appear in real-time without page refresh

### Phase 4: Optional Enhancements
- [ ] Add to listing page if desired
- [ ] Update calendar to use shared module
- [ ] Add unit tests for status module
- [ ] Add visual test cases for all 4 status colors

---

## APPENDIX: Common Gotchas

1. **Preloading is Critical**
   - If episodes aren't preloaded with `:media_files`, the status will always be MISSING
   - If episodes aren't preloaded with `:downloads`, DOWNLOADING won't detect active downloads
   - Current `show.ex` already has correct preloading at line 398

2. **Date Comparison**
   - Must compare dates, not datetimes: `Date.compare(episode.air_date, today)`
   - Episode.air_date is a Date, not DateTime
   - Use `Date.utc_today()` to get current date

3. **Download Status Values**
   - Valid statuses: "pending", "downloading", "completed", "failed", "cancelled"
   - Only "pending" and "downloading" indicate active downloads
   - "completed" should show as downloaded (file exists)
   - "failed" should show as missing (file doesn't exist)

4. **Empty Lists**
   - `Enum.any?([], _)` returns false - safe for no files/downloads
   - `episode.media_files` will be `[]` not nil if preloaded with no results
   - Use `Enum.empty?()` or `Enum.any?()` for safe checks

5. **Real-Time Updates**
   - show.ex already subscribes to "downloads" topic
   - When download status changes, entire media_item is reloaded
   - This is correct behavior - simpler than partial updates

