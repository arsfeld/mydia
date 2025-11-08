---
id: task-5
title: Implement OIDC authentication with Ueberauth
status: Done
assignee:
  - assistant
created_date: '2025-11-04 01:52'
updated_date: '2025-11-06 03:35'
labels:
  - authentication
  - security
  - oidc
dependencies:
  - task-4
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up OpenID Connect authentication using Ueberauth and Guardian for JWT tokens. Support OIDC providers like Authentik, Keycloak, Auth0. Include fallback local authentication for development.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Ueberauth and ueberauth_oidc dependencies configured
- [x] #2 Guardian set up for JWT token management
- [x] #3 OIDC callback routes implemented
- [x] #4 User session management working
- [x] #5 Role-based authorization (admin, user, readonly)
- [x] #6 Local auth fallback for development
- [x] #7 Authentication plugs created
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan for OIDC Authentication

### Stage 1: Add Dependencies
1. Uncomment and configure `ueberauth` and add `ueberauth_oidc` in mix.exs
2. Add `guardian` for JWT token management (~> 2.3)
3. Run `mix deps.get` to install dependencies

### Stage 2: Configure Guardian for JWT
1. Create `lib/mydia/auth/guardian.ex` - Guardian implementation module
2. Create `lib/mydia/auth/error_handler.ex` - Handle authentication errors
3. Configure Guardian in config files with secret key and token TTL

### Stage 3: Configure Ueberauth and OIDC Strategy
1. Configure Ueberauth providers in config/config.exs
2. Support configuration via environment variables for OIDC discovery URL, client ID/secret, scopes
3. Add environment-based config in config/runtime.exs

### Stage 4: Create Authentication Plugs
1. Create auth_pipeline.ex - Guardian pipeline for authenticated routes
2. Create ensure_authenticated.ex - Verify user is logged in
3. Create ensure_role.ex - Role-based authorization
4. Create api_auth.ex - API key authentication plug

### Stage 5: Implement OIDC Callback Routes and Controllers
1. Create auth_controller.ex with login, callback, logout actions
2. Add routes for OIDC authentication flow
3. Handle user creation/update from OIDC claims

### Stage 6: Session Management
1. Implement current_user assignment in LiveView on_mount hooks
2. Create user_auth.ex - LiveView authentication hooks

### Stage 7: Update Router Pipelines
1. Create :auth pipeline with Guardian verification
2. Create :require_authenticated and :require_admin pipelines
3. Protect routes appropriately

### Stage 8: Local Auth Fallback (Development)
1. Create session_controller.ex for local login
2. Add local login form view
3. Make it only available in development environment
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Testing Setup Complete

Added comprehensive testing infrastructure to `compose.override.yml`:

### Keycloak Service
- Added Keycloak container for OIDC testing
- Configured with admin/admin credentials
- Runs in dev mode with built-in H2 database
- Health checks enabled
- Exposed on port 8080

### Environment Variables
- Added `GUARDIAN_SECRET_KEY` for JWT token signing in development
- Documented OIDC configuration variables:
  - `OIDC_ISSUER` - Keycloak realm URL
  - `OIDC_CLIENT_ID` - OAuth client ID
  - `OIDC_CLIENT_SECRET` - OAuth client secret
  - `OIDC_REDIRECT_URI` - Callback URL
  - `OIDC_SCOPES` - OpenID scopes

### Documentation
- Created `docs/OIDC_TESTING.md` with step-by-step setup guide
- Includes Keycloak configuration instructions
- Documents user and role creation process
- Provides troubleshooting tips
- Alternative Authentik configuration included as comments

### Testing
All acceptance criteria verified:
1. ✅ Ueberauth and ueberauth_oidc dependencies configured
2. ✅ Guardian set up for JWT token management
3. ✅ OIDC callback routes implemented at `/auth/oidc/callback`
4. ✅ User session management working via Guardian
5. ✅ Role-based authorization (admin, user, readonly) supported
6. ✅ Local auth fallback available at `/auth/local/login`
7. ✅ Authentication plugs created (`:auth`, `:require_authenticated`)

The OIDC implementation is production-ready and can be tested locally using the provided Keycloak setup.
<!-- SECTION:NOTES:END -->
