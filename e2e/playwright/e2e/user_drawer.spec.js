import { test, expect } from '../support/test-setup';
import { forceLogin } from '../support/on-rails';

test.describe('User Drawer', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, { email: 'satoshi@example.com', redirect_to: '/' });
  });

  test('can open user drawer by clicking avatar', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    await expect(page.locator('.drawer-side')).toBeVisible();
    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await expect(page.getByRole('link', { name: /Billing & Credits/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /My Orders/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Logout/i })).toBeVisible();
  });

  test('can close user drawer by clicking X button', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    await expect(page.locator('.drawer-side')).toBeVisible();
    
    await page.getByLabel('close sidebar').nth(1).click();
    await expect(page.locator('.drawer-side')).not.toBeVisible();
  });

  test('can close user drawer by clicking overlay', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    await expect(page.locator('.drawer-side')).toBeVisible();
    
    await page.locator('.drawer-overlay').click();
    await expect(page.locator('.drawer-side')).not.toBeVisible();
  });

  test('can navigate to Billing & Credits', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    await page.getByRole('link', { name: /Billing & Credits/i }).click();
    await expect(page).toHaveURL(/\/tokens/);
  });

  test('can navigate to My Orders', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    await page.getByRole('link', { name: /My Orders/i }).click();
    await expect(page).toHaveURL(/\/orders/);
  });

  test('can logout from user drawer', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    await page.getByRole('button', { name: /Logout/i }).click();
    
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page.getByText('Signed out successfully')).toBeVisible();
    await expect(page).toHaveURL('/');
  });

  test('displays user name when available', async ({ page }) => {
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    const userInfo = page.locator('.font-semibold').first();
    await expect(userInfo).toBeVisible();
    await expect(userInfo).toContainText(/\S+/);
  });
});