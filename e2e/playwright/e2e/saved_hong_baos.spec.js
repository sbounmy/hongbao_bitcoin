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
    await expect(page.getByText('bc1qp2nl...s5526g').locator('visible=true').first()).toBeVisible(); // Shortened address (first 8 + last 6)

    // Check that stats are visible
    await expect(page.locator('.stat-value').getByText('₿0.00076171')).toBeVisible();
    await expect(page.locator('.stat-value').first().getByText('5')).toBeVisible();
    await expect(page.locator('.stat-value').getByText('$8')).toBeVisible();
    await expect(page.getByText('Loading...')).toBeVisible();
    await expect(page.getByText('0.00040657').first()).not.toBeVisible();    await app('perform_jobs');
    await app('perform_jobs');
    await expect(page.getByText('Loading...')).not.toBeVisible();
    await expect(page.getByText('0.00040657').first()).toBeVisible();
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

    // The rich_wallet fixture should be visible in the table
    await expect(page.getByRole('cell', { name: 'HODL HB' })).toBeVisible();

    // Check that shortened address format is displayed with external link icon
    await expect(page.getByText('bc1qyus6...5paulx').locator('visible=true').first()).toBeVisible();

    // Verify that address links to mempool
    const addressLink = page.locator('a[href*="mempool.space/address/"]').first();
    await expect(addressLink).toBeVisible();

    // Verify stats are shown with Bitcoin symbol
    await expect(page.getByText('₿0.00041171').first()).toBeVisible();

    // Check for status badge
    await expect(page.locator('.badge').first()).toBeVisible();
  });

  test('displays portfolio performance chart with correct data', async ({ page }) => {
    appVcrInsertCassette('saved_hong_baos_chart');

    // Navigate to saved hong baos page
    await page.goto('/saved_hong_baos');

    // Wait for chart to be rendered
    await expect(page.locator('.highcharts-container')).toBeVisible();

    // Check that series legends are visible
    await expect(page.getByText('Bitcoin Price')).toBeVisible();
    await expect(page.getByText('HongBao Value')).toBeVisible();
    await expect(page.getByText('HongBao Spent')).toBeVisible();

    // Verify chart has rendered data (check for SVG elements)
    const chartSvg = page.locator('.highcharts-container svg');
    await expect(chartSvg).toBeVisible();

    // Check that chart has series lines
    await expect(page.locator('.highcharts-series')).toHaveCount(3);

    // Verify avatar markers are rendered on the chart
    const avatarMarkers = page.locator('.highcharts-markers image.highcharts-point');
    await expect(avatarMarkers.first()).toBeVisible();

    // Verify the avatar marker has the correct source (DiceBear API)
    const markerSrc = await avatarMarkers.first().getAttribute('href');
    expect(markerSrc).toContain('api.dicebear.com');

    appVcrEjectCassette();
  });

});