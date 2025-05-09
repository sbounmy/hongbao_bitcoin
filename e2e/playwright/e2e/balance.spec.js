const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin , app } = require('../support/on-rails');

test.describe('Balance', () => {

  test('user can scan a qrcode', async ({ page }) => {
    await page.goto('/hong_baos');
    await expect(page.locator('body')).toContainText('QR Code');
  });
});