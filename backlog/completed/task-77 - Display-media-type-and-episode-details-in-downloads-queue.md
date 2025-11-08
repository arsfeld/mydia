---
id: task-77
title: Display media type and episode details in downloads queue
status: Done
assignee: []
created_date: '2025-11-05 15:45'
updated_date: '2025-11-05 16:00'
labels: []
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enhance the downloads queue UI to clearly show what type of media is being downloaded (Movie, TV Show, Episode) and relevant episode details (season/episode number) for TV content.

Currently, the downloads list shows the title but doesn't explicitly indicate:
- Whether it's a movie or TV show content
- For TV episodes: season and episode numbers (e.g., "S02E05")
- The media item the download belongs to

The download schema already has `media_item_id` (links to movie/show) and `episode_id` (links to specific episode), so the data is available. We need to:
1. Preload the necessary associations (media_item, episode) in the downloads context
2. Display media type badges/icons (🎬 Movie, 📺 TV Show)
3. Show episode identifiers (S##E##) for TV episode downloads
4. Consider showing the parent show title for episode downloads (e.g., "The Office - S02E05: The Dundies")

This will help users quickly understand what's being downloaded in the queue and differentiate between movies, full seasons, and individual episodes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Downloads queue displays a clear media type indicator (badge or icon) for each download item
- [x] #2 TV episode downloads show season and episode number in a standard format (S##E##)
- [x] #3 Episode downloads optionally show the parent TV show title alongside episode details
- [x] #4 The UI remains compact and doesn't clutter the existing download information
- [x] #5 Changes work correctly for both the Queue and Issues tabs
<!-- AC:END -->
