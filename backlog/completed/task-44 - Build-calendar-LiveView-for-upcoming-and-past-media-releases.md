---
id: task-44
title: Build calendar LiveView for upcoming and past media releases
status: Done
assignee: []
created_date: '2025-11-04 21:25'
updated_date: '2025-11-04 21:32'
labels: []
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a calendar interface that displays upcoming TV episode air dates and movie releases for monitored media items. The calendar helps users track when new content will be available and identify what recently aired that needs to be downloaded.

This is a core feature for media management, allowing users to:
- See what episodes are airing this week/month
- Plan downloads around release schedules  
- Identify missing episodes that recently aired
- Filter by media type (movies, TV shows, or both)

The calendar should display:
- TV episodes with air dates for monitored shows
- Movie releases (theatrical or digital) for monitored movies
- Color-coded status indicators (upcoming, available, downloaded, missing)
- Quick actions to search/download or view details

The implementation should follow the established patterns from other LiveViews (search, media library, downloads) and leverage the existing Episode and MediaItem schemas which already have air_date fields indexed in the database.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Calendar page is accessible at /calendar route with proper authentication
- [x] #2 Month view displays episodes and movies grouped by air/release date
- [x] #3 Users can navigate between months (previous/next/today buttons)
- [x] #4 Each calendar entry shows: title, season/episode info, media type, status
- [x] #5 Status indicators differentiate between upcoming (gray), available (blue), downloaded (green), and missing (red)
- [x] #6 Clicking a calendar entry opens the media detail view or episode detail modal
- [x] #7 Filter controls allow showing only movies, only TV shows, or both
- [x] #8 Empty states are shown when no monitored media has releases in the selected month
- [x] #9 Calendar updates in real-time when downloads complete or media monitoring changes
- [x] #10 Mobile responsive layout shows a condensed list view instead of calendar grid
<!-- AC:END -->
