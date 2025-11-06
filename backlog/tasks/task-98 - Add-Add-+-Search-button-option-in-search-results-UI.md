---
id: task-98
title: Add "Add + Search" button option in search results UI
status: To Do
assignee: []
created_date: '2025-11-06 04:32'
labels:
  - ui
  - ux-improvement
  - search
  - automation
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Background

Currently when adding media from search results, users can only "Add to Library". After adding, they need to navigate to the media detail page and click "Auto Search & Download" to trigger a search.

## Goal

Provide a second button option in search results: **"Add + Search"** that:
- Adds the item to the library
- Immediately queues an auto-search job
- Provides better UX by combining two steps into one

## Implementation

**Search Results UI Changes:**
- Keep existing "Add to Library" button (just adds, no search)
- Add new "Add + Search" button next to it
- Both buttons should be clear about their behavior

**Backend:**
- After creating media item, check if "search" flag is set
- If true, queue MovieSearch or TVShowSearch job based on type
- Return appropriate feedback message

**User Feedback:**
- "Added {title} to library" for regular add
- "Added {title} to library. Searching for releases..." for add + search

## Related

- Complements task-97 (button enable fix)
- Alternative to full auto-search-on-add configuration
<!-- SECTION:DESCRIPTION:END -->
