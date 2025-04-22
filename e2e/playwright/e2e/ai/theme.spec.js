const { test, expect } = require('../../support/test-setup');
const { appVcrInsertCassette, forceLogin } = require('../../support/on-rails');

test.describe('Theme', () => {

  test.beforeEach(async ({ page }) => {
    // Create admin user and authenticate
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });
  });

  const hexToRgb = hex =>
    hex.replace(/^#?([a-f\d])([a-f\d])([a-f\d])$/i
               ,(m, r, g, b) => '#' + r + r + g + g + b + b)
      .substring(1).match(/.{2}/g)
      .map(x => parseInt(x, 16))

  test('admin can view and edit theme properties', async ({ page }) => {
    await appVcrInsertCassette('ai_theme')
    await page.goto('/');
    await expect(page.locator('.bg-base-100').first()).toHaveCSS('background-color', 'oklch(0.9451 0.179 104.32)'); //theme default

    // Navigate to admin themes page
    await page.setExtraHTTPHeaders({
      Authorization: 'Basic '+btoa('satoshiisalive:this-is-just-a-test')
 })
    await page.goto('/admin/ai_themes/1/edit');
    // Verify existing values
    await expect(page.locator('#ai_theme_title')).toHaveValue('Dollar');
    await expect(page.locator('#ai_theme_ui_name')).toHaveValue('cyberpunk');

    // Set new theme values
    await page.getByLabel('UI Name').selectOption('sunset');
    await page.getByLabel('Color base 100').fill('#112fa3');

    // Submit the form
    await page.locator('input[type="submit"]').click();

    // Verify success message
    await expect(page.getByText('Theme was successfully updated')).toBeVisible();

    await page.goto('/');
    await expect(page.locator('.bg-base-100').first()).toHaveCSS('background-color', 'oklch(0.22 0.019 237.69)');
  });
});