const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin, turboCableConnected, app, appVcrEjectCassette } = require('../support/on-rails');

test.describe('Paper creation', () => {

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
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao'); // General check for balance display

     // Select styles
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();

    await expect(page.getByText('45-60 seconds')).toBeVisible();
    await app('perform_jobs');
    await expect(page.getByText('45-60 seconds')).toBeHidden();
    expect(await page.getByText('Select Theme').filter({ visible: true }).count()).toBe(1)

    await page.goto('/dashboard');
    await expect(page.locator('.badge')).toContainText('489 ₿ao'); // General check for balance display
  });

  test('can switch theme', async ({ page }) => {
    await page.goto('/papers/1/edit');
    await turboCableConnected(page);
    expect(await page.getByText('Select Theme').filter({ visible: true }).count()).toBe(1)

    await page.locator('#edit_paper_1').getByRole('button', { name: 'Euro' }).click()
    await expect(page.getByText('Ghibli Euro')).toBeVisible()
  });

  test('creating paper with None style does not deduct tokens', async ({ page }) => {
    await page.goto('/papers/new');
    await turboCableConnected(page);

    // Check initial balance
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao');

    // Select None style (free) - it should be first and have FREE badge
    await page.getByText('None').filter({ visible: true }).first().click({ force: true });

    // Verify FREE badge is visible
    await expect(page.getByText('FREE')).toBeVisible();

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    await expect(page.getByText('Processing...')).toBeHidden();

    // Generate paper
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();

    // Perform background jobs
    await app('perform_jobs');

    // Verify we're on edit page
    expect(await page.getByText('Select Theme').filter({ visible: true }).count()).toBe(1);

    // Go back to dashboard and verify balance unchanged
    await page.goto('/dashboard');
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao'); // No tokens deducted
  });

});