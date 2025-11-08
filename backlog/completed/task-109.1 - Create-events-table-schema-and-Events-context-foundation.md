---
id: task-109.1
title: Create events table schema and Events context foundation
status: Done
assignee:
  - assistant
created_date: '2025-11-06 18:46'
updated_date: '2025-11-06 19:16'
labels:
  - backend
  - database
  - foundation
dependencies: []
parent_task_id: task-109
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the database schema and core Events context module to support event tracking throughout the application.

## Scope

**Database:**
- Create events table with all required fields
- Add composite indexes for query performance
- Migration to create table

**Events Context:**
- `Mydia.Events` context module with CRUD operations
- `Mydia.Events.Event` Ecto schema
- Query functions with filtering (category, type, actor, resource, date range)
- `create_event/1` and `create_event_async/1` functions
- PubSub broadcast integration

**Testing:**
- Unit tests for event creation
- Tests for query filtering
- Tests for async event creation
- Tests for PubSub broadcasts

## Implementation Notes

- Use `:binary_id` for primary keys (consistent with app)
- `inserted_at` only (no updated_at, events are immutable)
- Metadata field stores JSON for flexibility
- Actor types: :user, :system, :job
- Severity levels: :info, :warning, :error (optional)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Events table created with migration
- [x] #2 All 6 indexes created (type, category, actor, resource, inserted_at, composite)
- [x] #3 Events.Event schema defined with proper types and validations
- [x] #4 Events.create_event/1 creates and broadcasts events
- [x] #5 Events.create_event_async/1 creates events without blocking
- [x] #6 Events.list_events/1 supports filtering by category, type, actor, resource, date
- [x] #7 Events.get_resource_events/3 retrieves events for specific resources
- [x] #8 Events.count_events/1 returns filtered count
- [x] #9 Test coverage > 90%
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Phase 1: Database Migration
Create `priv/repo/migrations/[timestamp]_create_events.exs` with:
- Events table with 10 fields (id, category, type, actor_type, actor_id, resource_type, resource_id, severity, metadata, inserted_at)
- 6 indexes for query performance (type, category, actor, resource, inserted_at, composite)
- Use TEXT for all fields (SQLite compatibility)

### Phase 2: Event Schema
Create `lib/mydia/events/event.ex`:
- Use binary_id primary key (consistent with app)
- Immutable events (inserted_at only, no updated_at)
- Validations for required fields and enums
- JSON metadata field for flexibility

### Phase 3: Events Context
Create `lib/mydia/events.ex` with:
- `create_event/1` - sync creation + PubSub broadcast
- `create_event_async/1` - async non-blocking creation
- `list_events/1` - query with filtering (category, type, actor, resource, date range)
- `get_resource_events/3` - events for specific resource
- `count_events/1` - filtered count

### Phase 4: Comprehensive Tests
Create `test/mydia/events_test.exs`:
- Event creation and validation tests
- PubSub broadcast verification
- Async creation tests
- Query filtering tests (all filter combinations)
- Target >90% coverage

**PubSub**: Broadcast to "events:all" with `{:event_created, event}` message format
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Use `:binary_id` for primary keys (consistent with app)
- `inserted_at` only (no updated_at, events are immutable)
- Metadata field stores JSON for flexibility
- Actor types: :user, :system, :job
- Severity levels: :info, :warning, :error (optional)
<!-- SECTION:DESCRIPTION:END -->

Completed implementation with all acceptance criteria met:
- Migration created with events table and 6 indexes
- Event schema with proper validations and immutable timestamps
- Events context with create_event/1, create_event_async/1, list_events/1, get_resource_events/3, count_events/1, delete_old_events/1
- PubSub integration for real-time broadcasts
- Comprehensive test suite with 37 tests, all passing
- Test coverage includes: event creation, validation, async operations, PubSub broadcasts, filtering, pagination, and cleanup
<!-- SECTION:NOTES:END -->
