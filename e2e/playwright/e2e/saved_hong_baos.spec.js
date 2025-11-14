import { test, expect } from '../support/test-setup';
import { forceLogin, appVcrInsertCassette, appVcrEjectCassette, app } from '../support/on-rails';


test.describe('Saved Hong Baos', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, {
      email: 'satoshi@example.com',
      redirect_to: '/saved_hong_baos',
    });
  });

  test('can create, view, and delete a saved hong bao', async ({ page }) => {
    appVcrInsertCassette('saved_hong_baos');
    // Click to add a new Hong Bao
    await page.getByRole('link', { name: /Add Hong Bao/ }).click();

    // Fill in the form
    await expect(page).toHaveURL('/saved_hong_baos/new');
    await page.getByLabel('Recipient Name').fill('My Friend Bob');
    await page.getByLabel('Bitcoin Address').fill('bc1qp2nl5ppm5zwr0lunl06f97wlfzr4dhmqs5526g');
    await page.getByLabel('Notes (optional)').fill('Birthday gift from 2024');

    // Submit the form
    await page.getByRole('button', { name: 'Save Hong Bao' }).click();

    // Verify the saved hong bao appears in the list
    await expect(page.getByText('My Friend Bob').locator('visible=true').first()).toBeVisible();
    await expect(page.getByText('bc1qp2nl...s5526g').locator('visible=true').first()).toBeVisible();

    // Check that stats are visible
    await expect(page.locator('.stat-value').getByText('₿0.00076171')).toBeVisible();
    await expect(page.locator('.stat-desc').first().getByText(/5/)).toBeVisible();
    await expect(page.locator('.stat-value').getByText('$8')).toBeVisible();
    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();
    await expect(visibleContainer.getByText('₿0.00040657')).not.toBeVisible();

    // await expect(page.locator(':is(#saved_hong_baos_cards, #saved_hong_baos_table)').getByText('₿0.00040657').first()).not.toBeVisible();
    await app('perform_jobs');
    // await expect(page.locator(':is(#saved_hong_baos_cards, #saved_hong_baos_table)').getByText('₿0.00040657').first()).toBeVisible();
    await expect(visibleContainer.getByText('₿0.00040657')).toBeVisible();
  });

  test('validates required fields', async ({ page }) => {
    await page.goto('/saved_hong_baos/new');

    // Try to submit empty form
    await page.getByRole('button', { name: 'Save Hong Bao' }).click();
    await page.locator('input#saved_hong_bao_name[required]')
    await page.locator('input#saved_hong_bao_address[required]')
  });

  test('validates Bitcoin address format', async ({ page }) => {
    await page.goto('/saved_hong_baos/new');

    // Fill with invalid address
    await page.getByLabel('Recipient Name').fill('Test User');
    await page.getByLabel('Bitcoin Address').fill('invalid_address_123');

    await page.getByRole('button', { name: 'Save Hong Bao' }).click();

    // Should show validation error
    await expect(page.getByText('is not a valid Bitcoin address')).toBeVisible();
  });

  test('prevents duplicate addresses for same user', async ({ page }) => {
    const testAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

    // Create first hong bao
    await page.goto('/saved_hong_baos/new');
    await page.getByLabel('Recipient Name').fill('First Entry');
    await page.getByLabel('Bitcoin Address').fill(testAddress);
    await page.getByRole('button', { name: 'Save Hong Bao' }).click();

    // Try to create duplicate
    await page.goto('/saved_hong_baos/new');
    await page.getByLabel('Recipient Name').fill('Second Entry');
    await page.getByLabel('Bitcoin Address').fill(testAddress);
    await page.getByRole('button', { name: 'Save Hong Bao' }).click();

    // Should show error
    await expect(page.getByText('has already been saved')).toBeVisible();
  });

  test('displays balance changes correctly', async ({ page }) => {
    // Navigate to saved hong baos page - fixture data should already be loaded
    await page.goto('/saved_hong_baos');

    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();

    // The rich_wallet fixture should be visible in the table
    await expect(visibleContainer.getByText('HODL HB' )).toBeVisible();

    // Check that shortened address format is displayed with external link icon
    await expect(visibleContainer.getByText('₿0.00041171')).toBeVisible();
    await expect(visibleContainer.getByText('bc1qyus6...5paulx')).toBeVisible();

    // Verify that address links to mempool
    const addressLink = page.locator('a[href*="mempool.space/address/"]').first();
    await expect(addressLink).toBeVisible();
  });

  test('displays portfolio performance chart with correct data', async ({ page }) => {
    appVcrInsertCassette('saved_hong_baos_chart');

    // Navigate to saved hong baos page
    await page.goto('/saved_hong_baos');

    // Wait for chart to be rendered
    await expect(page.locator('.highcharts-container')).toBeVisible();

    // Verify chart has rendered data (check for SVG elements)
    const chartSvg = page.locator('.highcharts-container svg');
    await expect(chartSvg).toBeVisible();

    // Check that chart has series lines
    await expect(page.locator('.highcharts-series')).toHaveCount(4); // 3 series + navigator (1 serie)

    // Verify avatar markers are rendered on the chart
    const avatarMarkers = page.locator('.highcharts-markers image.highcharts-point');
    await expect(avatarMarkers.first()).toBeVisible();

    // Verify the avatar marker has the correct source (DiceBear API)
    const markerSrc = await avatarMarkers.first().getAttribute('href');
    expect(markerSrc).toContain('api.dicebear.com');

    appVcrEjectCassette();
  });

  test('can attach a PDF on creation', async ({ page }) => {
    // Navigate to new saved hong bao form
    await page.goto('/saved_hong_baos/new');

    // Fill in the form
    await page.getByLabel('Recipient Name').fill('Test PDF User');
    await page.getByLabel('Bitcoin Address').fill('bc1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn');
    await page.getByLabel('Notes (optional)').fill('Testing PDF attachment');

    // Attach PDF file
    await page.getByLabel('Recovery File (optional)').setInputFiles('spec/fixtures/files/test.pdf');

    // Submit the form
    await page.getByRole('button', { name: 'Save Hong Bao' }).click();

    // Verify we're redirected to the saved hong baos page
    await expect(page).toHaveURL('/saved_hong_baos');

    // Verify the saved hong bao appears with a paperclip icon next to the name
    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();
    await expect(visibleContainer.getByText('Test PDF User')).toBeVisible();

    // Check for paperclip icon next to the name (indicates file is attached)
    const nameWithPaperclip = visibleContainer.locator('div:has-text("Test PDF User")').locator('xpath=..').first();
    await expect(nameWithPaperclip.locator('svg').first()).toBeVisible();
  });

  test('can attach a PDF on edit', async ({ page }) => {
    // Navigate to saved hong baos page where fixtures are loaded
    await page.goto('/saved_hong_baos');

    // Find the HODL HB fixture and click edit
    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();
    const hodlRow = visibleContainer.locator('tr:has-text("HODL HB"), div:has-text("HODL HB")').first();

    // Click the edit button (pencil icon)
    await hodlRow.locator('[title="Edit"]').click();

    // Wait for modal to open
    await expect(page.locator('dialog[open]')).toBeVisible();

    // Attach PDF file in the modal
    await page.getByLabel('Recovery File').setInputFiles('spec/fixtures/files/test.pdf');

    // Save changes
    await page.getByRole('button', { name: 'Save Changes' }).click();

    // Wait for modal to close and page to update
    await expect(page.locator('dialog[open]')).not.toBeVisible();

    // Verify paperclip icon appears next to HODL HB name
    await expect(visibleContainer.locator('div:has-text("HODL HB")').locator('svg').first()).toBeVisible();
  });

  test('can delete a PDF', async ({ page }) => {
    await page.goto('/saved_hong_baos');

    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();
    const withdrawnRow = visibleContainer.locator('tr:has-text("Withdrawn HB"), div:has-text("Withdrawn HB")').first();

    await withdrawnRow.locator('[title="Edit"]').click();
    await expect(page.locator('dialog[open]')).toBeVisible();
    await page.getByLabel('Recovery File').setInputFiles('spec/fixtures/files/test.pdf');
    await page.getByRole('button', { name: 'Save Changes' }).click();
    await expect(page.locator('dialog[open]')).not.toBeVisible();

    await withdrawnRow.locator('[title="Edit"]').click();
    await expect(page.locator('dialog[open]')).toBeVisible();

    await expect(page.getByText('test.pdf')).toBeVisible();

    page.on('dialog', dialog => dialog.accept()); // Auto-accept confirmation
    await page.locator('button:has(svg)').filter({ hasText: '' }).last().click(); // Trash button

    // File info should disappear
    await expect(page.getByText('test.pdf')).not.toBeVisible();

    // Close modal
    await page.getByRole('button', { name: 'Cancel' }).click();

    await page.goto('/saved_hong_baos');
    await expect(visibleContainer.locator('div:has-text("Withdrawn HB")').locator('svg')).not.toBeVisible();
  });

  test('can download a PDF', async ({ page }) => {
    await page.goto('/saved_hong_baos');

    const visibleContainer = page.locator('#saved_hong_baos_cards:visible, #saved_hong_baos_table:visible').first();
    const transactionsRow = visibleContainer.locator('tr:has-text("Made some transactions"), div:has-text("Made some transactions")').first();

    await transactionsRow.locator('[title="Edit"]').click();
    await expect(page.locator('dialog[open]')).toBeVisible();
    await page.getByLabel('Recovery File').setInputFiles('spec/fixtures/files/test.pdf');
    await page.getByRole('button', { name: 'Save Changes' }).click();
    await expect(page.locator('dialog[open]')).not.toBeVisible();

    const downloadPromise = page.waitForEvent('download');
    await visibleContainer.locator('div:has-text("Made some transactions")').locator('a:has(svg)').first().click();
    const download = await downloadPromise;

    expect(download.suggestedFilename()).toMatch(/\.pdf$/);
  });

});