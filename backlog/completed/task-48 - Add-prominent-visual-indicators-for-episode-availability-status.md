---
id: task-48
title: Add prominent visual indicators for episode availability status
status: Done
assignee:
  - assistant
created_date: '2025-11-04 21:44'
updated_date: '2025-11-04 22:01'
labels:
  - enhancement
  - ui
  - ux
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Improve the visibility of episode availability status in the media details page by using prominent color-coded indicators that match the calendar view color scheme.

**Extended Scope**: Also apply the same color-coded status indicators to the TV shows and movies listing pages to show at-a-glance availability status for entire media items.

## Color Code (matching calendar)
- **Blue**: Episode/Media is currently downloading
- **Green**: Episode/Media has been downloaded (file exists)
- **Red**: Episode/Media is missing (monitored but no file)
- **Gray/Muted**: Episode/Media is not monitored

## Visual Implementation Options
Consider one or more of these approaches:
1. **Colored border/background** on episode/media rows
2. **Status badge/pill** with icon and color
3. **Colored status icon** next to episode/media number
4. **Sidebar indicator** (colored bar on left edge of row)

## Requirements

### Episode States to Display (Details Page)
- Missing: Episode is monitored, aired (or no air date), but no file exists
- Downloaded: Episode has at least one media file
- Downloading: Episode has active downloads
- Not Monitored: Episode monitoring is disabled (show muted/gray)
- Future: Episode hasn't aired yet (show different state if applicable)

### Media Item States to Display (TV Shows/Movies Pages)
- Missing: Media is monitored, has aired episodes/released, but missing files
- Partial: Some episodes downloaded, some missing (TV shows only)
- Downloaded: All monitored episodes/movie have files
- Downloading: Has active downloads
- Not Monitored: Media monitoring is disabled

### UI Considerations
- Status should be immediately visible without interaction
- Color coding should be consistent across the app (calendar, details page, listing pages)
- Consider accessibility - use icons in addition to colors
- Status should update in real-time as downloads complete
- Show file quality/count for downloaded episodes (optional enhancement)
- On listing pages, show aggregate status for TV shows (e.g., "5/24 episodes")

## Implementation Notes
- Add helper functions to determine episode status based on:
  - `monitored` flag
  - `air_date` compared to current date
  - Existence of related `media_files`
  - Existence of active `downloads`
- Add helper functions to determine media item status (aggregate of episodes for TV shows)
- Update episode list template to show colored indicators
- Update TV shows and movies listing pages to show status indicators
- Ensure status updates via PubSub when downloads complete
- Consider adding tooltip with detailed status info on hover

## Related Features
- Episode rows should also show file size, quality profile if downloaded
- Download progress bar for episodes currently downloading
- Quick actions based on status (search for missing, view file for downloaded)
- Show episode count/progress on TV show cards (e.g., "5/24 episodes")
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Episode status is clearly visible using color coding
- [x] #2 Colors match calendar view (blue=downloading, green=downloaded, red=missing)
- [x] #3 Status updates in real-time when downloads complete
- [x] #4 Not monitored episodes are visually distinct
- [x] #5 Color scheme is accessible (uses icons + colors)
- [x] #6 Status is visible at a glance without interaction

- [x] #7 TV shows listing page shows status indicators for each show
- [x] #8 Movies listing page shows status indicators for each movie
- [x] #9 TV shows show aggregate status (e.g., partial download with episode count)
- [x] #10 Status indicators are consistent across all pages (details, listings, calendar)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan (Approved)

### Phase 1: Shared Status Logic
- Create `lib/mydia/media/episode_status.ex` with reusable helpers
- Functions: `get_episode_status/1`, `status_color/1`, `status_icon/1`, `status_label/1`
- Status priority: not_monitored → downloaded → upcoming → downloading → missing
- Use calendar view logic as reference (proven pattern)

### Phase 2: Media Details Page
- Update `show.html.heex` lines 271-286 (status column)
- Replace bookmark-only with status badge (DaisyUI badge component)
- Add icons for accessibility
- Show file details for downloaded episodes

### Phase 3: Aggregate Status for Media Items
- Add `get_media_status/1` helper to `lib/mydia/media.ex`
- Calculate aggregate for TV shows (partial, complete, missing)
- Return episode counts for display

### Phase 4: Update Listing Pages
- Update `index.html.heex` with status badges
- Add to grid view cards and table view
- Show episode counts for TV shows (e.g., "5/24 episodes")
- Update query to preload necessary data

### Phase 5: Real-Time Updates
- Verify existing PubSub integration works
- Test status updates when downloads complete

### Color Scheme (DaisyUI)
- Downloaded: green (badge-success) + check-circle icon
- Downloading: blue (badge-info) + arrow-down-tray icon
- Missing: red (badge-error) + exclamation-circle icon
- Not Monitored: gray (badge-ghost) + eye-slash icon
- Upcoming: light gray (badge-outline) + clock icon
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Add helper functions to determine episode status based on:
  - `monitored` flag
  - `air_date` compared to current date
  - Existence of related `media_files`
  - Existence of active `downloads`
- Update episode list template to show colored indicators
- Ensure status updates via PubSub when downloads complete
- Consider adding tooltip with detailed status info on hover

## Related Features
- Episode rows should also show file size, quality profile if downloaded
- Download progress bar for episodes currently downloading
- Quick actions based on status (search for missing, view file for downloaded)
<!-- SECTION:DESCRIPTION:END -->

## Implementation Complete

### Files Created
1. **lib/mydia/media/episode_status.ex** - New module with status determination logic
   - `get_episode_status/1` - Basic status (without downloads)
   - `get_episode_status_with_downloads/1` - Full status with download checking
   - `status_color/1` - DaisyUI badge color classes
   - `status_icon/1` - HeroIcon names
   - `status_label/1` - Human-readable labels
   - `status_details/1` - Detailed status for tooltips (includes quality, counts, progress)

### Files Modified

1. **lib/mydia/media.ex**
   - Added `get_media_status/1` function for aggregate status
   - Supports both TV shows and movies
   - Returns tuple: `{status, %{downloaded: count, total: count}}` for TV shows
   - Calculates partial downloads, upcoming episodes, etc.

2. **lib/mydia_web/live/media_live/show.ex**
   - Added EpisodeStatus alias import
   - Added helper functions: `get_episode_status/1`, `episode_status_color/1`, `episode_status_icon/1`, `episode_status_label/1`, `episode_status_details/1`

3. **lib/mydia_web/live/media_live/show.html.heex**
   - Replaced status column (lines 294-310) with status badge component
   - Uses tooltip with detailed status info
   - Shows icon + label (label hidden on small screens)
   - Color-coded badges with accessibility icons

4. **lib/mydia_web/live/media_live/index.ex**
   - Added EpisodeStatus alias import
   - Updated `build_query_opts/1` to preload episodes with media_files and downloads
   - Added helper functions: `get_media_item_status/1`, `media_status_color/1`, `media_status_icon/1`, `media_status_label/1`, `format_episode_count/1`

5. **lib/mydia_web/live/media_live/index.html.heex**
   - **Grid view (lines 218-242)**: Added status badge with episode counts below title
   - **List view (lines 300-311)**: Replaced monitored/unmonitored column with availability status badges
   - Both views show episode counts for TV shows (e.g., "5/24 episodes")

### Status Colors & Icons (DaisyUI + HeroIcons)
- **Downloaded**: Green (`badge-success`) + `hero-check-circle`
- **Downloading**: Blue (`badge-info`) + `hero-arrow-down-tray`
- **Missing**: Red (`badge-error`) + `hero-exclamation-circle`
- **Not Monitored**: Gray (`badge-ghost`) + `hero-eye-slash`
- **Upcoming**: Light gray (`badge-outline`) + `hero-clock`

### Real-Time Updates
PubSub integration already in place:
- show.ex subscribes to "downloads" topic (line 15)
- Handles download updates (lines 373-388)
- Status badges will update automatically when downloads complete

### Code Quality
- All code compiles successfully
- No new warnings introduced
- Code formatted with `mix format`
- Follows Phoenix/Elixir conventions
- Uses existing patterns (matching calendar view logic)
<!-- SECTION:NOTES:END -->
