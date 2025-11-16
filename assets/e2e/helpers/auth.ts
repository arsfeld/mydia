/**
 * Authentication helpers for E2E tests
 */
import { Page, expect } from '@playwright/test';
import { testUsers } from '../fixtures/users';

/**
 * Login as admin user using local authentication
 */
export async function loginAsAdmin(page: Page): Promise<void> {
  await login(page, testUsers.admin.username, testUsers.admin.password);
}

/**
 * Login as regular user using local authentication
 */
export async function loginAsUser(page: Page): Promise<void> {
  await login(page, testUsers.user.username, testUsers.user.password);
}

/**
 * Login with custom credentials using local authentication
 */
export async function login(page: Page, username: string, password: string): Promise<void> {
  // Navigate to local login page
  await page.goto('/auth/local/login');

  // Wait for login form to be visible
  await page.waitForSelector('form', { state: 'visible' });

  // Fill in credentials
  await page.fill('input[name="user[username]"]', username);
  await page.fill('input[name="user[password]"]', password);

  // Submit the form
  await page.click('button[type="submit"]');

  // Wait for redirect to homepage or successful login
  await page.waitForURL('/', { timeout: 5000 });

  // Verify we're logged in by checking for user-specific elements
  // (e.g., logout button, user menu, etc.)
  await page.waitForSelector('[data-test="user-menu"], .navbar', { timeout: 3000 });
}

/**
 * Mock OIDC login flow (for testing OIDC without real provider)
 * This assumes mock-oauth2-server is running
 */
export async function mockOIDCLogin(page: Page, email: string = 'test@example.com', name: string = 'Test User'): Promise<void> {
  // Navigate to OIDC login
  await page.goto('/auth/oidc');

  // The mock OAuth2 server should redirect us to an interactive login page
  // Fill in the mock login form if it appears
  const loginButton = page.locator('button:has-text("Sign in")').first();
  if (await loginButton.isVisible({ timeout: 2000 })) {
    await loginButton.click();
  }

  // Wait for redirect back to the app
  await page.waitForURL('/', { timeout: 5000 });
}

/**
 * Logout current user
 */
export async function logout(page: Page): Promise<void> {
  // Navigate to logout endpoint
  await page.goto('/auth/logout');

  // Wait for redirect to login page or homepage
  await page.waitForURL((url) => {
    return url.pathname === '/auth/local/login' ||
           url.pathname === '/' ||
           url.pathname === '/auth/login';
  }, { timeout: 5000 });
}

/**
 * Check if user is currently logged in
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  // Check for presence of user menu or other logged-in indicators
  const userMenu = await page.locator('[data-test="user-menu"], .navbar').count();
  return userMenu > 0;
}

/**
 * Ensure user is logged in, login if not
 */
export async function ensureLoggedIn(page: Page, username?: string, password?: string): Promise<void> {
  if (!await isLoggedIn(page)) {
    if (username && password) {
      await login(page, username, password);
    } else {
      await loginAsAdmin(page);
    }
  }
}
