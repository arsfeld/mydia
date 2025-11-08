---
id: task-25
title: Build admin configuration management and system observability UI
status: Done
assignee: []
created_date: '2025-11-04 03:52'
updated_date: '2025-11-06 03:15'
labels:
  - admin
  - ui
  - configuration
  - observability
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create comprehensive admin interface for monitoring system state and managing configuration. This includes a status dashboard showing current configuration, folder monitoring, download clients, and indexers, plus a configuration management system that allows UI-based changes to override file-based config (but not environment variables). The UI should clearly indicate the source of each configuration value (env var, database/UI, config.yml, or default) to provide full transparency to administrators.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Admin role can access system status and configuration features
- [x] #2 Configuration precedence is correctly implemented: env vars > database/UI > config.yml > defaults
- [x] #3 UI clearly shows configuration source for each setting
- [x] #4 All configuration changes made via UI are persisted to database
- [x] #5 Environment variables cannot be overridden by UI (read-only display)
- [x] #6 System follows docs/architecture/technical.md architecture and docs/product/product.md vision for self-hosting simplicity
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete (2025-11-06)

**All core functionality complete via subtasks:**

✅ **task-25.1**: Admin system status dashboard created
✅ **task-25.2**: Database schema for UI-managed configuration  
✅ **task-25.3**: Configuration resolution system with precedence
✅ **task-25.4**: Configuration management LiveView with source transparency
✅ **task-25.5**: REST API endpoints for configuration management (just completed!)
⚠️ **task-25.6**: Display real Oban statistics (To Do, Low priority - optional enhancement)

**All acceptance criteria met:**

✅ AC#1: Admin role can access system status and configuration features
✅ AC#2: Configuration precedence correctly implemented: env vars > database/UI > config.yml > defaults
✅ AC#3: UI clearly shows configuration source for each setting
✅ AC#4: All configuration changes made via UI are persisted to database
✅ AC#5: Environment variables cannot be overridden by UI (read-only display)
✅ AC#6: System follows architecture and product vision for self-hosting simplicity

**What was built:**

1. **Admin Status Dashboard** (/admin/status)
   - System overview with configuration sources
   - Library paths monitoring
   - Download clients status
   - Indexers status
   - Basic Oban job statistics (hardcoded for now)

2. **Configuration Management UI** (/admin/config)
   - Full configuration editor with source transparency
   - Create/update/delete database overrides
   - Read-only display for environment variables
   - Organized by category with search/filter

3. **Configuration System** (lib/mydia/settings.ex, lib/mydia/config/)
   - 4-layer precedence: env vars > database > YAML > defaults
   - Database schema for UI-managed settings
   - Runtime configuration resolution
   - Type-safe config with Ecto schemas

4. **REST API** (/api/v1/config)
   - GET /config - list all settings with sources
   - GET /config/:key - get specific setting
   - PUT /config/:key - update setting (creates DB override)
   - DELETE /config/:key - remove override
   - Admin-only access with proper authentication

**Remaining optional work:**

Only task-25.6 remains (displaying real Oban statistics instead of zeros). This is a low-priority enhancement that doesn't affect core functionality.

**System is production-ready** - administrators can configure and monitor the system via UI and API.
<!-- SECTION:NOTES:END -->
