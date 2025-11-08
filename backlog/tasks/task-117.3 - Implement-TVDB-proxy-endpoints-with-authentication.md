---
id: task-117.3
title: Implement TVDB proxy endpoints with authentication
status: To Do
assignee: []
created_date: '2025-11-08 03:05'
updated_date: '2025-11-08 03:18'
labels: []
dependencies: []
parent_task_id: task-117
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement proxy endpoints for TVDB API, including JWT authentication flow using a GenServer for token management. Support series search, metadata retrieval, and episode data fetching.

TVDB requires JWT token management, so implement a supervised GenServer that acquires tokens, caches them, and automatically refreshes before expiration to minimize authentication overhead.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 MetadataRelay.TVDB.Auth GenServer implemented for JWT management
- [ ] #2 JWT authentication flow with token caching in GenServer state
- [ ] #3 Token auto-refresh before expiration implemented
- [ ] #4 Auth GenServer added to supervision tree
- [ ] #5 MetadataRelay.TVDB.Client module created for API requests
- [ ] #6 Series search endpoint proxies TVDB search
- [ ] #7 Series metadata endpoint returns detailed series info

- [ ] #8 Episode data endpoints support season and episode queries
- [ ] #9 TVDB API credentials configured via environment variables
- [ ] #10 Error handling covers authentication failures gracefully
<!-- AC:END -->
