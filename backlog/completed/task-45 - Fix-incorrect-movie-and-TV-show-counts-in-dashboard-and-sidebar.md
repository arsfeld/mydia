---
id: task-45
title: Fix incorrect movie and TV show counts in dashboard and sidebar
status: Done
assignee: []
created_date: '2025-11-04 21:32'
updated_date: '2025-11-04 21:35'
labels: []
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The dashboard and sidebar are displaying incorrect counts for movies and TV shows in the library. These counts are important for users to understand their library size at a glance and need to accurately reflect the current state of the media library.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Dashboard displays accurate count of movies in the library
- [x] #2 Dashboard displays accurate count of TV shows in the library
- [x] #3 Sidebar displays accurate count of movies in the library
- [x] #4 Sidebar displays accurate count of TV shows in the library
- [x] #5 Counts update correctly when media items are added to the library
- [x] #6 Counts update correctly when media items are removed from the library
- [x] #7 Counts are consistent between dashboard and sidebar
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Fixed incorrect movie and TV show counts by implementing dynamic count fetching throughout the application.

### Changes Made

1. **Media Context (lib/mydia/media.ex)**
   - Added `count_movies/0` function to count movies in the library
   - Added `count_tv_shows/0` function to count TV shows in the library
   - Both functions use Ecto queries with `Repo.aggregate(:count)` for accurate counting

2. **Page Controller (lib/mydia_web/controllers/page_controller.ex)**
   - Updated `home/2` action to fetch movie and TV show counts
   - Passes counts to the home template as assigns

3. **Home Template (lib/mydia_web/controllers/page_html/home.html.heex)**
   - Updated Movies card to display `{@movie_count}` instead of hardcoded "0"
   - Updated TV Shows card to display `{@tv_show_count}` instead of hardcoded "0"

4. **Layouts Component (lib/mydia_web/components/layouts.ex)**
   - Added `movie_count` and `tv_show_count` as optional attributes to the `app/1` function
   - Implemented automatic count fetching using `assign_new/3` when counts are not provided
   - Updated sidebar navigation to display dynamic counts in badges

### How It Works

- **Dashboard**: PageController explicitly fetches counts and passes them to the template
- **Sidebar**: Layout component automatically fetches counts on every render using `assign_new/3`
- **Consistency**: Both use the same `Media.count_movies/0` and `Media.count_tv_shows/0` functions
- **Real-time Updates**: Counts are fetched fresh on each page load, ensuring they reflect any additions or deletions

### Benefits

- Counts accurately reflect the current state of the library
- Consistent counting logic across the application
- Automatic updates when media items are added or removed
- No manual intervention required from LiveViews (layout handles it automatically)
<!-- SECTION:NOTES:END -->
