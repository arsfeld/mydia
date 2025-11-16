/**
 * LiveView-specific helpers and assertions for E2E tests
 */
import { Page, expect } from '@playwright/test';

/**
 * Wait for LiveView to finish updating after an action
 * This waits for the phx-loading class to be removed
 */
export async function waitForLiveViewUpdate(page: Page, timeout: number = 5000): Promise<void> {
  // Wait for any loading indicators to disappear
  await page.waitForFunction(() => {
    const loadingElements = document.querySelectorAll('[phx-loading], .phx-loading');
    return loadingElements.length === 0 ||
           Array.from(loadingElements).every(el => !el.classList.contains('phx-loading'));
  }, { timeout });

  // Also wait for network to be idle
  await page.waitForLoadState('networkidle', { timeout });
}

/**
 * Assert that a flash message is displayed
 * @param page - Playwright page object
 * @param type - Flash message type ('info', 'error', 'success', 'warning')
 * @param message - Expected message text (can be substring)
 */
export async function assertFlashMessage(
  page: Page,
  type: 'info' | 'error' | 'success' | 'warning',
  message?: string
): Promise<void> {
  // Wait for flash message to appear
  const flashSelector = `[role="alert"], .alert, .flash-${type}, [data-test="flash-${type}"]`;
  await page.waitForSelector(flashSelector, { state: 'visible', timeout: 3000 });

  if (message) {
    // Check that the flash contains the expected message
    const flashElement = page.locator(flashSelector).first();
    await expect(flashElement).toContainText(message, { timeout: 2000 });
  }
}

/**
 * Assert that a LiveView stream has been updated
 * This checks for the presence of new items in a phx-update="stream" container
 *
 * @param page - Playwright page object
 * @param streamId - The ID of the stream container
 * @param expectedItemCount - Optional: expected number of items in the stream
 */
export async function assertStreamUpdated(
  page: Page,
  streamId: string,
  expectedItemCount?: number
): Promise<void> {
  // Wait for the stream container to exist
  const streamSelector = `#${streamId}[phx-update="stream"]`;
  await page.waitForSelector(streamSelector, { state: 'attached', timeout: 3000 });

  if (expectedItemCount !== undefined) {
    // Count direct children (stream items)
    await page.waitForFunction(
      ({ selector, count }) => {
        const container = document.querySelector(selector);
        if (!container) return false;
        return container.children.length === count;
      },
      { selector: streamSelector, count: expectedItemCount },
      { timeout: 5000 }
    );
  }
}

/**
 * Click an element and wait for LiveView to update
 */
export async function clickAndWaitForUpdate(page: Page, selector: string): Promise<void> {
  await page.click(selector);
  await waitForLiveViewUpdate(page);
}

/**
 * Fill a form field and wait for LiveView validation
 */
export async function fillAndWaitForValidation(page: Page, selector: string, value: string): Promise<void> {
  await page.fill(selector, value);
  // Trigger blur event to run validations
  await page.locator(selector).blur();
  // Wait a bit for validation to complete
  await page.waitForTimeout(500);
}

/**
 * Submit a LiveView form and wait for response
 */
export async function submitFormAndWait(page: Page, formSelector: string): Promise<void> {
  await page.locator(formSelector).locator('button[type="submit"]').click();
  await waitForLiveViewUpdate(page);
}

/**
 * Wait for a specific Phoenix event to be triggered
 * This is useful for testing custom events
 */
export async function waitForPhoenixEvent(page: Page, eventName: string, timeout: number = 5000): Promise<void> {
  await page.waitForFunction(
    (event) => {
      return new Promise((resolve) => {
        window.addEventListener(`phx:${event}`, () => resolve(true), { once: true });
        // Also resolve if the event was already triggered
        setTimeout(() => resolve(false), 100);
      });
    },
    eventName,
    { timeout }
  );
}

/**
 * Check if LiveView is connected
 */
export async function isLiveViewConnected(page: Page): Promise<boolean> {
  return await page.evaluate(() => {
    const liveSocket = (window as any).liveSocket;
    if (!liveSocket) return false;

    // Check if there are any connected views
    const views = liveSocket.main ? [liveSocket.main] : [];
    return views.some((view: any) => view.isConnected && view.isConnected());
  });
}

/**
 * Wait for LiveView to be fully connected and ready
 */
export async function waitForLiveViewReady(page: Page, timeout: number = 5000): Promise<void> {
  await page.waitForFunction(() => {
    const liveSocket = (window as any).liveSocket;
    return liveSocket && liveSocket.isConnected && liveSocket.isConnected();
  }, { timeout });
}
