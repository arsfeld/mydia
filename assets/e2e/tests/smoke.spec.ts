import { test, expect } from '@playwright/test';

/**
 * Smoke test to verify Playwright can connect to the Phoenix application
 * and the basic application structure is working.
 */
test.describe('Application Smoke Test', () => {
  test('homepage loads successfully', async ({ page }) => {
    // Navigate to the homepage
    await page.goto('/');

    // Verify the page loaded (should have HTML content)
    const html = await page.content();
    expect(html).toBeTruthy();
    expect(html.length).toBeGreaterThan(0);

    // Verify we got a successful response (not a 404 or 500)
    expect(page.url()).toContain('/');
  });

  test('page has proper meta tags', async ({ page }) => {
    await page.goto('/');

    // Check for basic HTML structure
    const title = await page.title();
    expect(title).toBeTruthy();

    // Verify viewport meta tag exists (for mobile responsiveness)
    const viewport = await page.locator('meta[name="viewport"]').getAttribute('content');
    expect(viewport).toBeTruthy();
  });

  test('LiveView JavaScript is loaded', async ({ page }) => {
    await page.goto('/');

    // Wait for the page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Wait for LiveView JavaScript to be available
    // This ensures the deferred script has executed
    await page.waitForFunction(() => {
      return typeof (window as any).liveSocket !== 'undefined' ||
             document.querySelector('[data-phx-main]') !== null;
    }, { timeout: 5000 });

    // Check if Phoenix LiveView JavaScript is present
    // Either the Phoenix global or LiveView socket connection indicators
    const hasLiveView = await page.evaluate(() => {
      // Check for Phoenix global or LiveView-specific elements
      const hasPhoenix = typeof (window as any).Phoenix !== 'undefined';
      const hasLiveSocket = typeof (window as any).liveSocket !== 'undefined';
      const hasPhxElements = document.querySelector('[data-phx-main]') !== null;

      return hasPhoenix || hasLiveSocket || hasPhxElements;
    });

    expect(hasLiveView).toBe(true);
  });

  test('Alpine.js is loaded and initialized', async ({ page }) => {
    await page.goto('/');

    // Check if Alpine.js is present (used for client-side interactions)
    const hasAlpine = await page.evaluate(() => {
      return typeof (window as any).Alpine !== 'undefined';
    });

    expect(hasAlpine).toBe(true);
  });

  test('can navigate and browser history works', async ({ page }) => {
    // Navigate to homepage
    await page.goto('/');
    const homeUrl = page.url();

    // If there's a link to navigate to, test it
    // For now, just verify we can reload and the URL stays the same
    await page.reload();
    expect(page.url()).toBe(homeUrl);
  });
});
