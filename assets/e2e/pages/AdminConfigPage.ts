/**
 * Page Object Model for the Admin Configuration page
 *
 * Encapsulates all interactions with the admin configuration pages including
 * managing indexers, download clients, quality profiles, and general settings.
 *
 * @class AdminConfigPage
 * @example
 * import { AdminConfigPage } from '../pages/AdminConfigPage';
 *
 * test('configure indexer', async ({ page }) => {
 *   const adminPage = new AdminConfigPage(page);
 *   await adminPage.goto();
 *   await adminPage.goToIndexersTab();
 *   await adminPage.clickAddIndexer();
 * });
 */
import { Page, expect, Locator } from "@playwright/test";

export class AdminConfigPage {
  /**
   * Creates a new AdminConfigPage instance
   * @param page - Playwright page object
   */
  constructor(private page: Page) {}

  // Tab Selectors
  // Note: Tab labels use short names - "Settings", "Quality", "Clients", "Indexers", "Library"

  private get generalTab() {
    return this.page.locator('button[role="tab"]:has-text("Settings")');
  }

  private get qualityTab() {
    return this.page.locator('button[role="tab"]:has-text("Quality")');
  }

  private get clientsTab() {
    return this.page.locator('button[role="tab"]:has-text("Clients")');
  }

  private get indexersTab() {
    return this.page.locator('button[role="tab"]:has-text("Indexers")');
  }

  private get libraryTab() {
    return this.page.locator('button[role="tab"]:has-text("Library")');
  }

  // Indexer Selectors

  private get addIndexerButton() {
    return this.page.locator('button[phx-click="new_indexer"]');
  }

  private get indexerModal() {
    return this.page.locator(".modal.modal-open .modal-box");
  }

  private get indexerNameInput() {
    return this.indexerModal.locator('input[id*="name"]').first();
  }

  private get indexerTypeSelect() {
    return this.indexerModal.locator("select").first();
  }

  private get indexerBaseUrlInput() {
    return this.indexerModal.locator('input[id*="base_url"]').first();
  }

  private get indexerApiKeyInput() {
    return this.indexerModal.locator('input[type="password"]').first();
  }

  private get saveIndexerButton() {
    return this.indexerModal.locator('button:has-text("Save")');
  }

  private get testIndexerButton() {
    return this.indexerModal
      .locator('button:has-text("Test Connection"), button:has-text("Test")')
      .first();
  }

  private get closeModalButton() {
    return this.indexerModal.locator(
      'button:has-text("Cancel"), button:has-text("Close")',
    );
  }

  /**
   * Get indexer row by name
   * @param name - Name of the indexer
   */
  private indexerRow(name: string) {
    return this.page
      .locator(`tr:has-text("${name}"), .card:has-text("${name}")`)
      .first();
  }

  /**
   * Get edit button for specific indexer
   * @param name - Name of the indexer
   */
  private editIndexerButton(name: string) {
    return this.indexerRow(name).locator(
      'button:has-text("Edit"), .btn:has-text("Edit")',
    );
  }

  /**
   * Get delete button for specific indexer
   * @param name - Name of the indexer
   */
  private deleteIndexerButton(name: string) {
    return this.indexerRow(name).locator(
      'button:has-text("Delete"), .btn:has-text("Delete")',
    );
  }

  // Download Client Selectors

  private get addDownloadClientButton() {
    return this.page.locator('button[phx-click="new_download_client"]');
  }

  private get clientModal() {
    return this.page.locator(".modal.modal-open .modal-box");
  }

  private get clientNameInput() {
    return this.clientModal.locator('input[id*="name"]').first();
  }

  private get clientTypeSelect() {
    return this.clientModal.locator("select").first();
  }

  private get clientHostInput() {
    return this.clientModal.locator('input[id*="host"]').first();
  }

  private get clientPortInput() {
    return this.clientModal.locator('input[id*="port"]').first();
  }

  private get clientUsernameInput() {
    return this.clientModal.locator('input[id*="username"]').first();
  }

  private get clientPasswordInput() {
    return this.clientModal.locator('input[type="password"]').first();
  }

  private get clientUseSslCheckbox() {
    return this.clientModal.locator('input[type="checkbox"]').first();
  }

  private get saveClientButton() {
    return this.clientModal.locator('button:has-text("Save")');
  }

  private get testClientButton() {
    return this.clientModal
      .locator('button:has-text("Test Connection"), button:has-text("Test")')
      .first();
  }

  /**
   * Get download client row by name
   * @param name - Name of the download client
   */
  private clientRow(name: string) {
    return this.page
      .locator(`tr:has-text("${name}"), .card:has-text("${name}")`)
      .first();
  }

  /**
   * Get edit button for specific download client
   * @param name - Name of the download client
   */
  private editClientButton(name: string) {
    return this.clientRow(name).locator(
      'button:has-text("Edit"), .btn:has-text("Edit")',
    );
  }

  /**
   * Get delete button for specific download client
   * @param name - Name of the download client
   */
  private deleteClientButton(name: string) {
    return this.clientRow(name).locator(
      'button:has-text("Delete"), .btn:has-text("Delete")',
    );
  }

  // General Settings Selectors

  /**
   * Get toggle switch for a setting by key
   * @param key - Setting key (e.g., "crash_reporting.enabled")
   */
  private settingToggle(key: string) {
    return this.page.locator(
      `input[type="checkbox"][name*="${key}"], .toggle[phx-value-key="${key}"]`,
    );
  }

  // Flash Message Selectors

  private get successMessage() {
    return this.page.locator(
      '#flash-info, [role="alert"]:has-text("success"), .alert-success',
    );
  }

  private get errorMessage() {
    return this.page.locator(
      '#flash-error, [role="alert"]:has-text("error"), [role="alert"]:has-text("failed"), .alert-error',
    );
  }

  // Navigation Actions

  /**
   * Navigate to the admin configuration page
   * @example
   * await adminPage.goto();
   */
  async goto() {
    await this.page.goto("/admin/config");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to General Settings tab
   * @example
   * await adminPage.goToGeneralTab();
   */
  async goToGeneralTab() {
    await this.generalTab.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to Quality Profiles tab
   * @example
   * await adminPage.goToQualityTab();
   */
  async goToQualityTab() {
    await this.qualityTab.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to Download Clients tab
   * @example
   * await adminPage.goToClientsTab();
   */
  async goToClientsTab() {
    await this.clientsTab.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to Indexers tab
   * @example
   * await adminPage.goToIndexersTab();
   */
  async goToIndexersTab() {
    await this.indexersTab.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to Library Paths tab
   * @example
   * await adminPage.goToLibraryTab();
   */
  async goToLibraryTab() {
    await this.libraryTab.click();
    await this.page.waitForLoadState("networkidle");
  }

  // Indexer Actions

  /**
   * Click the "Add Indexer" button
   * @example
   * await adminPage.clickAddIndexer();
   */
  async clickAddIndexer() {
    await this.addIndexerButton.click();
    await expect(this.indexerModal).toBeVisible({ timeout: 5000 });
  }

  /**
   * Fill in indexer configuration form
   * @param config - Indexer configuration object
   * @example
   * await adminPage.fillIndexerForm({
   *   name: 'My Prowlarr',
   *   type: 'prowlarr',
   *   baseUrl: 'http://localhost:9696',
   *   apiKey: 'test-key-123'
   * });
   */
  async fillIndexerForm(config: {
    name: string;
    type?: string;
    baseUrl: string;
    apiKey?: string;
  }) {
    await this.indexerNameInput.fill(config.name);

    if (config.type) {
      await this.indexerTypeSelect.selectOption(config.type);
    }

    await this.indexerBaseUrlInput.fill(config.baseUrl);

    if (config.apiKey) {
      await this.indexerApiKeyInput.fill(config.apiKey);
    }
  }

  /**
   * Save the indexer configuration
   * @example
   * await adminPage.saveIndexer();
   */
  async saveIndexer() {
    await this.saveIndexerButton.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Test indexer connection
   * @example
   * await adminPage.testIndexerConnection();
   */
  async testIndexerConnection() {
    await this.testIndexerButton.click();
    await this.page.waitForTimeout(1000); // Wait for test to complete
  }

  /**
   * Edit an existing indexer
   * @param name - Name of the indexer to edit
   * @example
   * await adminPage.editIndexer('My Prowlarr');
   */
  async editIndexer(name: string) {
    await this.editIndexerButton(name).click();
    await expect(this.indexerModal).toBeVisible({ timeout: 5000 });
  }

  /**
   * Delete an indexer
   * @param name - Name of the indexer to delete
   * @example
   * await adminPage.deleteIndexer('My Prowlarr');
   */
  async deleteIndexer(name: string) {
    // Handle confirmation dialog
    this.page.on("dialog", (dialog) => dialog.accept());
    await this.deleteIndexerButton(name).click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Close the indexer modal
   * @example
   * await adminPage.closeModal();
   */
  async closeModal() {
    await this.closeModalButton.click();
  }

  // Download Client Actions

  /**
   * Click the "Add Download Client" button
   * @example
   * await adminPage.clickAddDownloadClient();
   */
  async clickAddDownloadClient() {
    await this.addDownloadClientButton.click();
    await expect(this.clientModal).toBeVisible({ timeout: 5000 });
  }

  /**
   * Fill in download client configuration form
   * @param config - Download client configuration object
   * @example
   * await adminPage.fillDownloadClientForm({
   *   name: 'qBittorrent',
   *   type: 'qbittorrent',
   *   host: 'localhost',
   *   port: '8080',
   *   username: 'admin',
   *   password: 'adminpass'
   * });
   */
  async fillDownloadClientForm(config: {
    name: string;
    type?: string;
    host: string;
    port: string;
    username?: string;
    password?: string;
    useSsl?: boolean;
  }) {
    await this.clientNameInput.fill(config.name);

    if (config.type) {
      await this.clientTypeSelect.selectOption(config.type);
    }

    await this.clientHostInput.fill(config.host);
    await this.clientPortInput.fill(config.port);

    if (config.username) {
      await this.clientUsernameInput.fill(config.username);
    }

    if (config.password) {
      await this.clientPasswordInput.fill(config.password);
    }

    if (config.useSsl !== undefined) {
      const currentlyChecked = await this.clientUseSslCheckbox.isChecked();
      if (config.useSsl !== currentlyChecked) {
        await this.clientUseSslCheckbox.click();
      }
    }
  }

  /**
   * Save the download client configuration
   * @example
   * await adminPage.saveDownloadClient();
   */
  async saveDownloadClient() {
    await this.saveClientButton.click();
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Test download client connection
   * @example
   * await adminPage.testDownloadClientConnection();
   */
  async testDownloadClientConnection() {
    await this.testClientButton.click();
    await this.page.waitForTimeout(1000); // Wait for test to complete
  }

  /**
   * Edit an existing download client
   * @param name - Name of the download client to edit
   * @example
   * await adminPage.editDownloadClient('qBittorrent');
   */
  async editDownloadClient(name: string) {
    await this.editClientButton(name).click();
    await expect(this.clientModal).toBeVisible({ timeout: 5000 });
  }

  /**
   * Delete a download client
   * @param name - Name of the download client to delete
   * @example
   * await adminPage.deleteDownloadClient('qBittorrent');
   */
  async deleteDownloadClient(name: string) {
    // Handle confirmation dialog
    this.page.on("dialog", (dialog) => dialog.accept());
    await this.deleteClientButton(name).click();
    await this.page.waitForLoadState("networkidle");
  }

  // General Settings Actions

  /**
   * Toggle a setting switch
   * @param key - Setting key
   * @example
   * await adminPage.toggleSetting('crash_reporting.enabled');
   */
  async toggleSetting(key: string) {
    await this.settingToggle(key).click();
    await this.page.waitForTimeout(500); // Wait for setting to save
  }

  // Assertions

  /**
   * Assert that the admin config page is loaded
   * @throws {Error} If page title is not visible
   * @example
   * await adminPage.assertPageLoaded();
   */
  async assertPageLoaded() {
    await expect(
      this.page.locator('h1:has-text("Configuration")'),
    ).toBeVisible();
  }

  /**
   * Assert that indexer exists in the list
   * @param name - Name of the indexer
   * @throws {Error} If indexer is not found
   * @example
   * await adminPage.assertIndexerExists('My Prowlarr');
   */
  async assertIndexerExists(name: string) {
    await expect(this.indexerRow(name)).toBeVisible({ timeout: 5000 });
  }

  /**
   * Assert that indexer does not exist in the list
   * @param name - Name of the indexer
   * @throws {Error} If indexer is found
   * @example
   * await adminPage.assertIndexerNotExists('Deleted Indexer');
   */
  async assertIndexerNotExists(name: string) {
    await expect(this.indexerRow(name)).not.toBeVisible();
  }

  /**
   * Assert that download client exists in the list
   * @param name - Name of the download client
   * @throws {Error} If download client is not found
   * @example
   * await adminPage.assertDownloadClientExists('qBittorrent');
   */
  async assertDownloadClientExists(name: string) {
    await expect(this.clientRow(name)).toBeVisible({ timeout: 5000 });
  }

  /**
   * Assert that download client does not exist in the list
   * @param name - Name of the download client
   * @throws {Error} If download client is found
   * @example
   * await adminPage.assertDownloadClientNotExists('Deleted Client');
   */
  async assertDownloadClientNotExists(name: string) {
    await expect(this.clientRow(name)).not.toBeVisible();
  }

  /**
   * Assert that a success message is displayed
   * @param message - Expected success message text (can be substring)
   * @throws {Error} If success message is not visible or doesn't contain text
   * @example
   * await adminPage.assertSuccessMessage('saved successfully');
   */
  async assertSuccessMessage(message?: string) {
    await expect(this.successMessage).toBeVisible({ timeout: 5000 });
    if (message) {
      await expect(this.successMessage).toContainText(message);
    }
  }

  /**
   * Assert that an error message is displayed
   * @param message - Expected error message text (can be substring)
   * @throws {Error} If error message is not visible or doesn't contain text
   * @example
   * await adminPage.assertErrorMessage('Connection failed');
   */
  async assertErrorMessage(message?: string) {
    await expect(this.errorMessage).toBeVisible({ timeout: 5000 });
    if (message) {
      await expect(this.errorMessage).toContainText(message);
    }
  }

  /**
   * Assert that indexer modal is visible
   * @throws {Error} If modal is not visible
   * @example
   * await adminPage.assertIndexerModalVisible();
   */
  async assertIndexerModalVisible() {
    await expect(this.indexerModal).toBeVisible();
  }

  /**
   * Assert that download client modal is visible
   * @throws {Error} If modal is not visible
   * @example
   * await adminPage.assertClientModalVisible();
   */
  async assertClientModalVisible() {
    await expect(this.clientModal).toBeVisible();
  }
}
