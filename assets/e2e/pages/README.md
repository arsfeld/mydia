# E2E Page Objects

This directory contains Page Object Model (POM) classes for E2E tests.

## Purpose

Page objects encapsulate page structure and interactions, making tests more maintainable:
- Provide reusable methods for page interactions
- Hide implementation details from tests
- Make tests easier to read and maintain
- Centralize selectors and page knowledge

## Example

```typescript
// login-page.ts
import { Page } from '@playwright/test';

export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/auth/login');
  }

  async login(email: string) {
    await this.page.fill('[name="email"]', email);
    await this.page.click('button[type="submit"]');
    await this.page.waitForURL('/');
  }
}
```
