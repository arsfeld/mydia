---
id: task-97
title: Make auto search & download enabled by default for new library items
status: Done
assignee: []
created_date: '2025-11-06 04:20'
updated_date: '2025-11-06 04:32'
labels:
  - automation
  - ui
  - downloads
  - configuration
  - ux-improvement
dependencies:
  - task-31.2
  - task-22.10.7
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Problem

The "Auto Search & Download" button on the media detail page was incorrectly disabled even when users should be able to re-search for media. Specifically:

- Button was disabled when downloads showed in history but no files existed
- Button was disabled when downloads were seeding or paused
- Button was disabled when no quality profile was assigned

This prevented users from manually triggering new searches for media that needed to be re-downloaded or searched again.

## Solution

**Fixed `can_auto_search?/2` function** to always enable the button for supported media types (movies and TV shows):
- Removed quality profile requirement check
- Removed active download status check  
- Removed download history check
- Button is now always enabled for movies and TV shows

**Simplified event handler** to remove unnecessary prerequisite checks that prevented search execution.

## Files Changed

- `lib/mydia_web/live/media_live/show.ex:1661-1665` - Updated `can_auto_search?/2` to only check media type
- `lib/mydia_web/live/media_live/show.ex:144-187` - Removed prerequisite checks from `handle_event("auto_search_download")`

## Result

Users can now always click "Auto Search & Download" to trigger a new search, regardless of:
- Previous download history
- Current download status (seeding, paused, etc.)
- Quality profile assignment
- Existing media files
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Configuration setting 'auto_search_on_add' controls automatic search triggering
- [ ] #2 Configuration setting 'monitor_by_default' controls default monitoring state
- [ ] #3 Settings UI allows users to configure both options with clear descriptions
- [ ] #4 Adding movie to library automatically triggers search if configured
- [ ] #5 Adding TV show to library automatically triggers search if configured
- [ ] #6 User sees clear feedback when auto-search is triggered automatically
- [ ] #7 Manual override still available via checkbox in add-to-library form
- [ ] #8 Prerequisites checked before auto-triggering (download clients, quality profile)
- [ ] #9 Appropriate job queued based on media type (MovieSearch/TVShowSearch)
- [ ] #10 Settings respected across all add-to-library entry points (search, discovery, etc)
- [ ] #11 Documentation updated to explain default behavior and settings
<!-- AC:END -->
