---
id: task-102
title: Create default admin user in production with random or env-provided password
status: Done
assignee: []
created_date: '2025-11-06 14:56'
updated_date: '2025-11-06 15:06'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add automatic admin user creation on production deployment startup if no admin user exists. The system should:

1. Check on application startup if an admin user exists
2. If no admin user exists:
   - Generate a random secure password OR use a pre-hashed password from environment variable
   - Create the admin user with the password
   - Display the generated password in the console (only if randomly generated)
3. Support environment variable `ADMIN_PASSWORD_HASH` for providing pre-hashed password
4. Only log/display passwords for randomly generated ones (not from env vars)

This ensures production deployments always have an admin user for initial access without requiring manual database manipulation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 On startup, system checks if any admin user exists in the database
- [x] #2 If no admin user exists and ADMIN_PASSWORD_HASH env var is set, create admin user with that hash
- [x] #3 If no admin user exists and no env var is set, generate random secure password and create admin user
- [x] #4 Random password is displayed in console/logs on startup (prominently, with clear instructions)
- [x] #5 Pre-hashed password from env var is never logged or displayed
- [x] #6 Admin user creation only happens once (idempotent - doesn't recreate on subsequent startups)
- [x] #7 Documentation updated to explain ADMIN_PASSWORD_HASH environment variable usage
- [x] #8 Default admin username is configurable or uses a sensible default (e.g., 'admin')
<!-- AC:END -->
