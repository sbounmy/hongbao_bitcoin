const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin, turboCableConnected, app } = require('../support/on-rails');

test.describe('Bundle generation', () => {

  test.beforeEach(async ({ page }) => {
    // Create admin user and authenticate
    await appVcrInsertCassette('bundle', { serialize_with: 'compressed', allow_playback_repeats: true })
    await forceLogin(page, {
      email: 'satoshi@example.com',
      redirect_to: '/dashboard'
    });
  });

  test('user can create a bundle', async ({ page }) => {
    await page.goto('/papers/new');
    await turboCableConnected(page);
    await expect(page.locator('.drawer-side')).toContainText('490 ₿ao'); // General check for balance display

     // Select styles
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    const count = await page.locator('#main-content .papers-item-component').count();

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();

    await expect(page.locator('#preview-column .papers-item-component')).toHaveCount(count + 2);
    await app('perform_jobs');
    await expect(page.locator('#preview-column .papers-item-component .bg-cover')).toHaveCount(4); // 2 papers, 2 faces
    await expect(page.locator('#preview-column .papers-item-component .bg-cover').first()).toHaveAttribute('style', /background-image: url\(\'\/rails\/active_storage\/blobs\/redirect\/.*\)/);
    await expect(page.locator('.drawer-side')).toContainText('488 ₿ao'); // General check for balance display
  });

  test('can overwrite quality in url', async ({ page }) => {
    await page.goto('/papers/new?quality=low');
    await turboCableConnected(page);
    await expect(page.locator('.drawer-side')).toContainText('490 ₿ao'); // General check for balance display
     // Select styles
     await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });

     // Upload image
     await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
     const count = await page.locator('#main-content .papers-item-component').count();

     await expect(page.getByText('Processing...')).toBeHidden();
     await page.getByRole('button', { name: 'Generate' }).click();
     await expect(page.getByText('Processing...')).toBeVisible();
     await expect(page.getByText('Processing...')).toBeHidden();

     await expect(page.locator('#preview-column .papers-item-component')).toHaveCount(count + 2);
     await app('perform_jobs');
     await expect(page.locator('#preview-column .papers-item-component .bg-cover')).toHaveCount(4); // 2 papers, 2 faces
     await expect(page.locator('#preview-column .papers-item-component .bg-cover').first()).toHaveAttribute('style', /background-image: url\(\'\/rails\/active_storage\/blobs\/redirect\/.*\)/);
     await expect(page.locator('.drawer-side')).toContainText('488 ₿ao'); // General check for balance display
   });
});