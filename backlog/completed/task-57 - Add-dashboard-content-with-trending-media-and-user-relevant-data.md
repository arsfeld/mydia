---
id: task-57
title: Add dashboard content with trending media and user-relevant data
status: Done
assignee: []
created_date: '2025-11-05 02:50'
updated_date: '2025-11-05 03:07'
labels:
  - enhancement
  - ui
  - dashboard
  - metadata
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enhance the dashboard to display engaging content for both new users and existing heavy users. This should include:

**Trending Content:**
- Trending TV shows (from metadata relay `/tv/trending`)
- Trending movies (from metadata relay `/movies/trending`)
- Display with posters, titles, and relevant metadata

**User-Relevant Data:**
- For new users: Showcase popular content to help them discover and start monitoring
- For existing users: 
  - Recently added episodes for monitored shows
  - Upcoming releases for monitored media
  - Download activity summary
  - Storage statistics

**Additional Considerations:**
- Responsive layout that works well on mobile and desktop
- Use DaisyUI components for consistent styling
- Implement proper loading states and error handling
- Consider caching trending data to reduce API calls
- Make sections configurable/hideable per user preference
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Dashboard displays trending TV shows from metadata relay
- [x] #2 Dashboard displays trending movies from metadata relay
- [x] #3 New users see discoverable content to help them get started
- [x] #4 Existing users see personalized data relevant to their monitoring activity
- [x] #5 All content displays with proper loading and error states
- [x] #6 Layout is responsive and works on mobile/tablet/desktop
- [x] #7 Trending data is cached appropriately to avoid excessive API calls
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

### Trending API Support
- Added `fetch_trending/2` callback to `Mydia.Metadata.Provider` behavior
- Implemented trending endpoints in `Mydia.Metadata.Provider.Relay`:
  - `/tmdb/movies/trending` for trending movies
  - `/tmdb/tv/trending` for trending TV shows
- Added convenience functions in `Mydia.Metadata` context:
  - `trending_movies/0` - Fetches trending movies
  - `trending_tv_shows/0` - Fetches trending TV shows

### Caching Layer
- Created `Mydia.Metadata.Cache` GenServer with ETS-based caching
- Implements TTL-based expiration (default: 1 hour)
- Automatic cleanup of expired entries every 10 minutes
- Added to application supervision tree
- Trending data is cached to reduce API calls

### Dashboard Enhancement
- Converted home page from `PageController` to `DashboardLive.Index`
- Updated router to use LiveView for the home route (`/`)
- Dashboard displays:
  - Stats cards (movies, TV shows, downloads, storage)
  - Trending movies with posters and metadata
  - Trending TV shows with posters and metadata
  - Recent episodes (last 7 days) for monitored content
  - Upcoming episodes (next 7 days) for monitored content
- Responsive grid layouts for mobile/tablet/desktop
- Proper loading states and error handling
- Empty states for new users

### User-Relevant Data
- Shows "Your Activity" section for users with monitored content
- Recent episodes display with:
  - Show title, season/episode number, episode title
  - Air date
  - File availability indicator
- Upcoming episodes display with show and episode details
- Conditionally shown only when user has monitored content

### Files Created/Modified
- Created: `lib/mydia_web/live/dashboard_live/index.ex`
- Created: `lib/mydia_web/live/dashboard_live/index.html.heex`
- Created: `lib/mydia/metadata/cache.ex`
- Modified: `lib/mydia/metadata/provider.ex`
- Modified: `lib/mydia/metadata/provider/relay.ex`
- Modified: `lib/mydia/metadata.ex`
- Modified: `lib/mydia/application.ex`
- Modified: `lib/mydia_web/router.ex`

### Testing Notes
To test the implementation:
1. Run `mix precommit` to compile and check for issues
2. Start the server and navigate to the home page
3. Verify trending content loads
4. Add some monitored TV shows and verify "Your Activity" appears
5. Check that caching reduces API calls on subsequent visits
<!-- SECTION:NOTES:END -->
