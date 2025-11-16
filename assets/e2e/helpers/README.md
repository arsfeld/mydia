# E2E Test Helpers

This directory contains helper functions and utilities for E2E tests.

## Purpose

Helpers provide reusable functionality including:
- Authentication helpers (login, logout, session management)
- Common assertions and waiters
- Database setup/teardown
- API interaction helpers

## Example

```typescript
// auth.ts
import { Page } from '@playwright/test';

export async function login(page: Page, email: string) {
  await page.goto('/auth/login');
  await page.fill('[name="email"]', email);
  await page.click('button[type="submit"]');
  await page.waitForURL('/');
}
```
