# E2E Test Fixtures

This directory contains test data and fixtures for E2E tests.

## Purpose

Fixtures provide consistent, reusable test data including:
- Mock API responses
- Sample media metadata
- User accounts
- Configuration data

## Format

Fixtures should be TypeScript/JSON files that export test data:

```typescript
export const testUser = {
  email: 'test@example.com',
  name: 'Test User'
};
```
