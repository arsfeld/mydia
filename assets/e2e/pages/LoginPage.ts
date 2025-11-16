/**
 * Page Object for the Login page
 */
import { Page, expect } from '@playwright/test';

export class LoginPage {
  constructor(private page: Page) {}

  // Selectors
  private get usernameInput() {
    return this.page.locator('input[name="user[username]"]');
  }

  private get passwordInput() {
    return this.page.locator('input[name="user[password]"]');
  }

  private get submitButton() {
    return this.page.locator('button[type="submit"]');
  }

  private get oidcButton() {
    return this.page.locator('a:has-text("Sign in with OIDC"), button:has-text("Sign in with OIDC")');
  }

  private get errorMessage() {
    return this.page.locator('[role="alert"], .alert-error, .flash-error');
  }

  // Actions
  async goto() {
    await this.page.goto('/auth/local/login');
    await this.page.waitForLoadState('networkidle');
  }

  async fillUsername(username: string) {
    await this.usernameInput.fill(username);
  }

  async fillPassword(password: string) {
    await this.passwordInput.fill(password);
  }

  async clickSubmit() {
    await this.submitButton.click();
  }

  async login(username: string, password: string) {
    await this.fillUsername(username);
    await this.fillPassword(password);
    await this.clickSubmit();
    // Wait for navigation
    await this.page.waitForURL('/', { timeout: 5000 });
  }

  async clickOIDCLogin() {
    await this.oidcButton.click();
  }

  // Assertions
  async assertLoginFormVisible() {
    await expect(this.usernameInput).toBeVisible();
    await expect(this.passwordInput).toBeVisible();
    await expect(this.submitButton).toBeVisible();
  }

  async assertErrorMessage(message: string) {
    await expect(this.errorMessage).toBeVisible();
    await expect(this.errorMessage).toContainText(message);
  }

  async assertOnLoginPage() {
    await expect(this.page).toHaveURL(/\/auth\/(local\/)?login/);
  }
}
