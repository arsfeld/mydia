---
id: task-3
title: Create database schema and migrations for media management
status: Done
assignee: []
created_date: '2025-11-04 01:52'
updated_date: '2025-11-04 02:32'
labels:
  - database
  - migrations
  - schema
dependencies:
  - task-2
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the core database schema from docs/architecture/technical.md including media_items, episodes, media_files, quality_profiles, downloads, users, and api_keys tables. Use SQLite-compatible types (TEXT for UUIDs, JSON as TEXT, INTEGER for booleans).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Migration files created for all core tables
- [x] #2 Indexes created on frequently queried fields
- [x] #3 Foreign key constraints properly defined
- [x] #4 Check constraints for enums implemented
- [x] #5 Migrations run successfully with `mix ecto.migrate`
- [x] #6 SQLite WAL mode and optimizations configured
<!-- AC:END -->
