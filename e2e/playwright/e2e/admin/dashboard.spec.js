import { test, expect } from '../../support/test-setup';
import { forceLogin } from '../../support/on-rails';

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/products'
    });
  });

  test('drawer works across navigation', async ({ page }) => {
    // set to mobile screen
    await page.setViewportSize({ width: 375, height: 667 });
    await page.getByRole('button', { name: 'Toggle main navigation menu' }).click();
    await expect(page.locator('#main-menu')).toBeVisible();
    await page.locator('#main-menu').getByText('Orders').click();
    await expect(page.getByText('New Order')).toBeVisible();
    await page.getByRole('button', { name: 'Toggle main navigation menu' }).click();
    await page.locator('#main-menu').getByText('Papers').click();
    await expect(page.getByText('New Paper')).toBeVisible();
  });
});