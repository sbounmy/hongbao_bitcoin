const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin , app } = require('../support/on-rails');

test.describe('Bundle generation', () => {

  test.beforeEach(async ({ page }) => {
    // Create admin user and authenticate
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });
  });

  test('user can create a bundle', async ({ page }) => {
    pending 'skip until we find out how to perform jobs'
    test.setTimeout(1_200_000); // slow test
    await appVcrInsertCassette('bundle')

     // Select styles
    await page.getByText('Ghibli').filter({ visible: true }).first().click({ force: true });
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    const count = await page.locator('#main-content .papers-item-component').count();

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();
    await app('perform_jobs');
    // this should be done through turbo frame
    await page.waitForTimeout(700_000); // jobs takes around chatgpt API 60s
    await page.goto('/');
    await expect(page.locator('#main-content .papers-item-component')).toHaveCount(count + 2);
  });
});