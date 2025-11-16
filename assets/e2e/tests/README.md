# E2E Tests

This directory contains end-to-end test files using Playwright.

## Organization

Tests should be organized by feature area:
- `auth/` - Authentication and authorization tests
- `media/` - Media search, library, and playback tests
- `admin/` - Admin configuration UI tests
- `realtime/` - LiveView and real-time update tests

## Naming Convention

Test files should follow the pattern: `feature.spec.ts`

Examples:
- `auth/login.spec.ts`
- `media/search.spec.ts`
- `admin/indexers.spec.ts`
