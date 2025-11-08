---
id: task-117.7
title: Update Mydia to use self-hosted metadata relay
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
Update the Mydia application configuration to point to the self-hosted metadata relay deployed on Fly.io instead of the unreliable external service.

Update default_relay_config() to use environment variable for flexibility between development and production. Verify that all metadata operations work correctly with the new relay service.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 lib/mydia/metadata.ex default_relay_config() updated to use METADATA_RELAY_URL env var
- [ ] #2 Fallback to Fly.io URL if METADATA_RELAY_URL not set
- [ ] #3 docker-compose.yml updated with METADATA_RELAY_URL environment variable
- [ ] #4 .env.example updated with METADATA_RELAY_URL documentation
- [ ] #5 Movie search returns results via self-hosted relay
- [ ] #6 TV show search returns results via self-hosted relay
- [ ] #7 Detailed metadata fetching works for both movies and TV shows
- [ ] #8 Image URLs resolve correctly through relay service

- [ ] #9 Season/episode data fetching works for TV shows
- [ ] #10 Integration tests pass using self-hosted relay
- [ ] #11 Fallback behavior documented if relay is unavailable
<!-- AC:END -->
