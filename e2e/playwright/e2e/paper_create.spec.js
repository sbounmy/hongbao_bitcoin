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

  test('user can upload an image and enhance with AI', async ({ page }) => {
    // Capture browser console logs for debugging
    page.on('console', msg => console.log(`[BROWSER] ${msg.type()}: ${msg.text()}`));

    await page.goto('/papers/new');
    await turboCableConnected(page);
    console.log('[TEST] Initial turboCableConnected done');
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao'); // General check for balance display

    await page.locator('#toolbar').getByRole('button', { name: 'Photo' }).click();
    await page.locator('#photo-sheet-input').setInputFiles('spec/fixtures/files/satoshi.jpg');
    await page.getByRole('button', { name: 'Enhance with AI' }).click();

    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });
    console.log('[TEST] Clicking Generate button...');
    await page.getByRole('button', { name: /Generate/ }).click();

    console.log('[TEST] Waiting for loading indicator to be visible...');
    await expect(page.getByText('45-60 seconds')).toBeVisible();
    await app('perform_jobs');
    await expect(page.getByText('45-60 seconds')).toBeHidden();

    await page.goto('/dashboard');
    await expect(page.locator('.badge')).toContainText('489 ₿ao'); // General check for balance display
  });

  test('can switch theme', async ({ page }) => {
    await page.goto('/papers/new');
    const frontBg = page.locator('[data-editor-target="frontBackground"]')
    const initialBase64 = await frontBg.getAttribute('src')

    await turboCableConnected(page);
    await page.getByRole('button', {name: /Theme/}).click()
    await expect(page.getByText('Dollar').first()).toBeVisible()
    await page.locator('body').getByText('Euro', { exact: true }).click();
    await page.getByRole('button', {name: 'Done'}).first().click()

    await expect(frontBg).not.toHaveAttribute('src', initialBase64)
  });

  test('creating paper with no AI does not deduct tokens', async ({ page }) => {
    await page.goto('/papers/new');
    await turboCableConnected(page);

    // Check initial balance
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao');

    // Upload image
    await page.locator('#toolbar').getByRole('button', { name: 'Photo' }).click();
    await page.locator('#photo-sheet-input').setInputFiles('spec/fixtures/files/satoshi.jpg');
    await page.waitForTimeout(1_000)
    await page.getByRole('button', { name: 'Done' }).click();
    await expect(page.locator('#photo-sheet-input')).not.toBeVisible()
    await expect(page.locator('.badge').first()).toContainText('490 ₿ao');
  });

  // test('user can change qrcode destination');

  // test('user can add custom text item');

  // test('user can change element position');

});
