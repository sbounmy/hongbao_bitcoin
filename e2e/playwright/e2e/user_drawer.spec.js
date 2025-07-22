import { test, expect } from '../support/test-setup';
import { forceLogin } from '../support/on-rails';

test.describe('User Drawer', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, { email: 'satoshi@example.com', redirect_to: '/' });
  });

  test('can open user drawer by clicking avatar', async ({ page }) => {
    // Click on the avatar to open the drawer - using the label that contains the ₿ao text
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Verify drawer sidebar is visible
    await expect(page.locator('.drawer-side')).toBeVisible();
    
    // Verify user information is displayed
    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    
    // Verify menu items are visible
    await expect(page.getByRole('link', { name: /Billing & Credits/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /My Orders/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Logout/i })).toBeVisible();
  });

  test('can close user drawer by clicking X button', async ({ page }) => {
    // Open the drawer
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Verify drawer is open
    await expect(page.locator('.drawer-side')).toBeVisible();
    
    // Click the X button to close the drawer
    await page.getByLabel('close sidebar').nth(1).click();
    
    // Verify drawer is closed
    await expect(page.locator('.drawer-side')).not.toBeVisible();
  });

  test('can close user drawer by clicking overlay', async ({ page }) => {
    // Open the drawer
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Verify drawer is open
    await expect(page.locator('.drawer-side')).toBeVisible();
    
    // Click the overlay to close the drawer
    await page.locator('.drawer-overlay').click();
    
    // Verify drawer is closed
    await expect(page.locator('.drawer-side')).not.toBeVisible();
  });

  test('can navigate to Billing & Credits', async ({ page }) => {
    // Open the drawer
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Click on Billing & Credits link
    await page.getByRole('link', { name: /Billing & Credits/i }).click();
    
    // Verify navigation to tokens page
    await expect(page).toHaveURL(/\/tokens/);
  });

  test('can navigate to My Orders', async ({ page }) => {
    // Open the drawer
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Click on My Orders link
    await page.getByRole('link', { name: /My Orders/i }).click();
    
    // Verify navigation to orders page
    await expect(page).toHaveURL(/\/orders/);
  });

  test('can logout from user drawer', async ({ page }) => {
    // Open the drawer
    await page.locator('label').filter({ hasText: '₿ao' }).click();
    
    // Click on Logout button
    await page.getByRole('button', { name: /Logout/i }).click();
    
    // Verify signed out notification appears
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page.getByText('Signed out successfully')).toBeVisible();
    
    // Verify redirect to root page
    await expect(page).toHaveURL('/');
  });
});