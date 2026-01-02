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

    await page.goto('/papers/new');
    await expect(page.locator('.badge').first()).toContainText('489 ₿ao'); // General check for balance display
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

  test('user can top up with correct address in Mt Pelerin widget', async ({ page }) => {
    await page.goto('/papers/new');
    await turboCableConnected(page);

    // Wait for wallet generation and get public address
    const publicAddrInput = page.locator('#public_address_text');
    await expect(publicAddrInput).toHaveValue(/^bc1/);
    const publicAddr = await publicAddrInput.inputValue();

    // Go to finish screen
    await page.getByRole('button', { name: /Next/ }).click();

    // Download PDF (required to enable Fund wallet)
    const downloadPromise = page.waitForEvent('download');
    await page.getByRole('button', { name: 'Download PDF' }).click();
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    // Open Fund drawer
    const fundButton = page.getByRole('button', { name: 'Fund wallet' });
    await expect(fundButton).toBeEnabled();
    await fundButton.click();

    // Verify Mt Pelerin iframe has correct address in URL
    const iframeElement = page.locator('iframe[data-mt-pelerin-target="iframe"]');
    await expect(iframeElement).toBeVisible();

    // Method 1: Verify URL parameter
    const iframeSrc = await iframeElement.getAttribute('src');
    const url = new URL(iframeSrc);
    expect(url.searchParams.get('addr')).toBe(publicAddr);
  });

  test('Mt Pelerin widget updates when user regenerates keys', async ({ page }) => {
    test.setTimeout(60_000)
    await page.goto('/papers/new');
    await turboCableConnected(page);

    // Get initial address
    const publicAddrInput = page.locator('#public_address_text');
    await expect(publicAddrInput).toHaveValue(/^bc1/);
    const initialAddr = await publicAddrInput.inputValue();

    // Open Keys drawer
    await page.getByRole('button', { name: 'Keys' }).click();

    // Regenerate keys 3 times
    for (let i = 0; i < 3; i++) {
      await page.locator('#bitcoin-generate').click();
      await page.waitForTimeout(500); // Wait for key generation
    }

    // Get the latest address
    const latestAddr = await publicAddrInput.inputValue();
    expect(latestAddr).not.toBe(initialAddr); // Should be different

    // Close drawer and go to finish screen
    await page.keyboard.press('Escape');
    await page.getByRole('button', { name: /Next/ }).click();

    // Download PDF
    const downloadPromise = page.waitForEvent('download');
    await page.getByRole('button', { name: 'Download PDF' }).click();
    await downloadPromise;

    // Open Fund drawer
    await page.getByRole('button', { name: 'Fund wallet' }).click();

    // Verify Mt Pelerin has the LATEST address
    const iframeElement = page.locator('iframe[data-mt-pelerin-target="iframe"]');
    await expect(iframeElement).toBeVisible();

    const iframeSrc = await iframeElement.getAttribute('src');
    const url = new URL(iframeSrc);
    expect(url.searchParams.get('addr')).toBe(latestAddr);
  });

});
