---
id: task-117.2
title: Implement TMDB proxy endpoints with passthrough functionality
status: Done
assignee: []
created_date: '2025-11-08 03:05'
updated_date: '2025-11-08 03:33'
labels: []
dependencies: []
parent_task_id: task-117
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement proxy endpoints that mirror TMDB v3 API structure for movie and TV show search and metadata retrieval. Use Req library (already used in Mydia) for HTTP requests with proper authentication and error handling.

Create a TMDB client module that forwards requests to TMDB API and returns responses in the exact same format.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 MetadataRelay.TMDB.Client module created using Req library
- [x] #2 GET /tmdb/movies/search endpoint proxies to TMDB
- [x] #3 GET /tmdb/tv/search endpoint proxies to TMDB for TV shows
- [x] #4 GET /tmdb/movies/{id} endpoint returns detailed movie metadata
- [x] #5 GET /tmdb/tv/shows/{id} endpoint returns detailed TV show metadata
- [x] #6 GET /tmdb/movies/{id}/images and /tmdb/tv/shows/{id}/images endpoints work
- [x] #7 GET /tmdb/tv/shows/{id}/{season} endpoint returns season data
- [x] #8 GET /tmdb/movies/trending and /tmdb/tv/trending endpoints implemented

- [x] #9 GET /configuration endpoint proxies TMDB configuration
- [x] #10 TMDB API key configured via environment variable (TMDB_API_KEY)
- [x] #11 Proper error handling returns appropriate HTTP status codes
- [x] #12 Response format matches TMDB v3 API structure exactly
<!-- AC:END -->
