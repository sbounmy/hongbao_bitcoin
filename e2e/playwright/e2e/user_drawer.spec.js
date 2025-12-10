import { test, expect } from '../support/test-setup';
import { forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('User Bottom Sheet', () => {
  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('stripe_products', { allow_playback_repeats: true });
    await forceLogin(page, { email: 'satoshi@example.com', redirect_to: '/dashboard' });
  });

  test.afterEach(async () => {
    await appVcrEjectCassette();
  });

  test('can open user menu by clicking avatar', async ({ page }) => {
    // Click the user avatar (label that triggers bottom sheet)
    await page.locator('label[for="user-bottom-sheet"]:visible').click();

    // Bottom sheet should be visible
    await expect(page.locator('.modal-box')).toBeVisible();
    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await expect(page.getByRole('link', { name: /Billing & Credits/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /My Orders/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Logout/i })).toBeVisible();
  });

  test('can close user menu by clicking X button', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();
    await expect(page.locator('.modal-box')).toBeVisible();

    await page.getByLabel('close sidebar').click();
    await expect(page.locator('.modal-box')).not.toBeVisible();
  });

  test('can close user menu by clicking backdrop', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();
    await expect(page.locator('.modal-box')).toBeVisible();
    await expect(page.locator('.modal-backdrop')).toBeVisible();

    // Click on the top-left corner of backdrop to avoid modal-box interception
    await page.locator('.modal-backdrop').first().click({ position: { x: 10, y: 10 } });
    await expect(page.locator('.modal-box')).not.toBeVisible();
  });

  test('can navigate to Billing & Credits', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();
    await page.getByRole('link', { name: /Billing & Credits/i }).click();
    await expect(page).toHaveURL(/\/tokens/);
  });

  test('can navigate to My Orders', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();
    await page.getByRole('link', { name: /My Orders/i }).click();
    await expect(page).toHaveURL(/\/orders/);
  });

  test('can logout from user menu', async ({ page }) => {
    await expect(page.locator('nav')).toContainText('satoshi');
    await page.locator('label[for="user-bottom-sheet"]:visible').click();
    await page.getByRole('button', { name: /Logout/i }).click();
    await expect(page.getByText('Signed out successfully')).toBeVisible();
    await expect(page.locator('nav')).not.toContainText('satoshi');
  });

  test('displays user name when available', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();

    const userInfo = page.locator('.modal-box .font-semibold').first();
    await expect(userInfo).toBeVisible();
    await expect(userInfo).toContainText(/\S+/);
  });

  test('displays token balance', async ({ page }) => {
    await page.locator('label[for="user-bottom-sheet"]:visible').click();

    // Token balance should be visible in the bottom sheet
    await expect(page.locator('.modal-box')).toContainText('₿ao');
  });
});
