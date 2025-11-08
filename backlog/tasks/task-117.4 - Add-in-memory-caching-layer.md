---
id: task-117.4
title: Add in-memory caching layer
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
Implement intelligent in-memory caching using Cachex to reduce external API calls and prevent rate limiting. Cache metadata responses with appropriate TTL values based on data volatility.

Cachex provides built-in TTL, LRU eviction, and metrics - perfect for this use case without requiring external dependencies like Redis.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Cachex added to supervision tree with appropriate configuration
- [ ] #2 MetadataRelay.Cache module wraps Cachex operations
- [ ] #3 Plug middleware intercepts GET requests and checks cache
- [ ] #4 Cached responses served without external API calls
- [ ] #5 TTL configured: 24h for metadata, 7d for images, 1h for trending
- [ ] #6 Cache key based on method:path:query_string
- [ ] #7 LRU eviction with max 1000 entries configured

- [ ] #8 Cache hit/miss metrics logged via telemetry
- [ ] #9 Cache persists during runtime and clears on restart
<!-- AC:END -->
