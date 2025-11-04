# Episode Availability Status - Quick Reference

## Status Colors (Consistent with Calendar)

| Status | Color | Class | Icon | When |
|--------|-------|-------|------|------|
| Downloaded | Green | `badge-success` | `hero-check-circle` | Has media files |
| Downloading | Blue | `badge-info` | `hero-arrow-down-tray` | Active downloads |
| Upcoming | Gray | `badge-ghost` | `hero-calendar` | Air date is future |
| Missing | Red | `badge-error` | `hero-exclamation-triangle` | No files, not downloading |

## Files to Edit

### Must Edit
1. `/lib/mydia_web/live/media_live/show.html.heex` - Line 271-286 (status column)
2. `/lib/mydia_web/live/media_live/show.ex` - Add status helper function

### Should Create
3. `/lib/mydia/media/episode_status.ex` - New reusable module

### Optional (Future)
4. `/lib/mydia_web/live/calendar_live/index.ex` - Refactor to use shared module
5. `/lib/mydia_web/live/media_live/index.ex` - Add episode status if needed

## Key Code Patterns

### Determining Status
```elixir
defp get_episode_status(episode) do
  today = Date.utc_today()
  
  cond do
    Enum.any?(episode.media_files, & &1.path) -> :downloaded
    Date.compare(episode.air_date, today) == :gt -> :upcoming
    Enum.any?(episode.downloads, &(&1.status in ["pending", "downloading"])) -> :downloading
    true -> :missing
  end
end
```

### Displaying Status Badge
```heex
<td>
  <% status = get_episode_status(episode) %>
  <span class={["badge badge-sm", status_badge_class(status)]}>
    <.icon name={status_icon(status)} class="w-3 h-3 mr-1" />
    {status_label(status)}
  </span>
</td>
```

### Status Helpers
```elixir
defp status_badge_class(:downloaded), do: "badge-success"
defp status_badge_class(:downloading), do: "badge-info"
defp status_badge_class(:upcoming), do: "badge-ghost"
defp status_badge_class(:missing), do: "badge-error"

defp status_icon(:downloaded), do: "hero-check-circle"
defp status_icon(:downloading), do: "hero-arrow-down-tray"
defp status_icon(:upcoming), do: "hero-calendar"
defp status_icon(:missing), do: "hero-exclamation-triangle"

defp status_label(:downloaded), do: "Downloaded"
defp status_label(:downloading), do: "Downloading"
defp status_label(:upcoming), do: "Upcoming"
defp status_label(:missing), do: "Missing"
```

## Data Already Available

✓ `episode.media_files` - Preloaded at show.ex line 401
✓ `episode.downloads` - Preloaded at show.ex line 401
✓ `episode.air_date` - Available in episode schema
✓ Real-time updates via PubSub - Already subscribed in show.ex line 11

## Current Preload (show.ex line 398)
```elixir
[
  quality_profile: [],
  episodes: [:media_files, downloads: :media_item],  ← Already correct!
  media_files: [],
  downloads: []
]
```

## Testing Checklist

- [ ] Episode with files shows DOWNLOADED (green)
- [ ] Episode with active download shows DOWNLOADING (blue)
- [ ] Episode aired but no files/downloads shows MISSING (red)
- [ ] Episode not yet aired shows UPCOMING (gray)
- [ ] Status updates in real-time when download completes
- [ ] Works on both desktop and mobile views
- [ ] Icons and badges render correctly

## Database Queries Reference

### Get Episodes with Status Info
From `media.ex` line 340:
```elixir
Media.list_episodes_by_air_date(start_date, end_date)
# Returns computed has_files and has_downloads fields
```

### Used in Calendar
Already computes has_files and has_downloads via EXISTS subqueries

## Related Tasks

- Task 46: Unify episode monitoring toggle in details page
- Task 47: Add monitor/unmonitor season actions
- Task 48: Add prominent visual indicators for episode availability status (THIS ONE)

---

**Recommendation:** Create `episode_status.ex` module first, then use it in both `show.ex` and calendar. This keeps the code DRY and makes testing easier.
