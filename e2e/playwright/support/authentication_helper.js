import { test as base } from '@playwright/test';

// Extend the base test with authentication
export const test = base.extend({
  // Add authenticated page fixture
  authenticatedPage: async ({ page }, use) => {
    // Function to force login a user
    const forceLogin = async (userAttributes = {}) => {
      const defaultAttributes = {
        email: 'test@example.com',
        password: 'password',
      };

      const attributes = { ...defaultAttributes, ...userAttributes };

      // Use the cypress-playwright-on-rails forceLogin endpoint
      await page.goto('/cypress_rails_login');
      await page.evaluate(async (attrs) => {
        await window.testHelpers.forceLogin(attrs);
      }, attributes);
    };

    // Attach forceLogin to the page
    page.forceLogin = forceLogin;

    // Pass the enhanced page object to the test
    await use(page);
  },
});