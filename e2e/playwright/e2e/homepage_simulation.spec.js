import { test, expect } from '../support/test-setup';
import { appVcrInsertCassette, appVcrEjectCassette, app, timecop } from '../support/on-rails';

test.describe('Homepage Bitcoin Gifting Simulation', () => {

  test.beforeEach(async ({}) => {
    await test.setTimeout(60_000);
  });

  test.afterEach(async () => {
    await timecop.return()
    await appVcrEjectCassette();
  });

  test('displays the simulation form with default values', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots', { limit: 365 });
    await page.goto('/');

    await expect(page.getByText('Bitcoin is the best performing asset')).toBeVisible();

    // Check simulation form is visible
    await expect(page.getByText('If I had gifted Bitcoin on')).toBeVisible();

    // Check default event amounts are displayed
    const christmasInput = page.getByRole('spinbutton', { name: '' }).first();
    await expect(christmasInput).toHaveValue('50');

    // Check years selector (using label to be specific since there are birthday month/day selectors)
    const yearsSelect = page.locator('select[name="simulation[years]"]');
    await expect(yearsSelect).toContainText('1 year');

    const viewFullButton = page.getByRole('link', { name: 'View full simulator' });
    await viewFullButton.click();

    // Should navigate to /simulation
    await expect(page).toHaveURL(/\/simulation/);

    // Full simulation should show chart and table
    await expect(page.getByText('Gift History')).toBeVisible();
  });

  test('displays default stats results', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots');
    await page.goto('/');

    // Check stats cards are visible
    await expect(page.getByText('I would have gifted')).toBeVisible();
    await expect(page.getByText('Worth today')).toBeVisible();

    // Check "Total Bitcoin accumulated" is visible with year
    await expect(page.getByText(/Total:.*/)).toBeVisible();
    await expect(page.getByText(/since \d{4}/)).toBeVisible();
  });

  test('updates stats when changing event amounts', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots');
    await page.goto('/');

    const initialAmount = await page.locator('#gift-value').first().textContent();

    // Change Christmas amount from 50 to 200
    const christmasInput = page.getByRole('spinbutton', { name: '' }).first();
    await christmasInput.clear();
    await christmasInput.fill('200');

    // Wait for auto-submit and stats update
    await page.waitForTimeout(1000);

    // Verify stats have changed
    const newAmount = await page.locator('#today-value').first().textContent();
    expect(newAmount).not.toBe(initialAmount);
  });

  test('updates stats when changing birthday date', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots');
    await page.goto('/');

    // Find birthday row
    const birthdayRow = page.locator('text=Birthday').locator('..');

    // Change birthday month
    const monthSelect = birthdayRow.locator('select').first();
    await monthSelect.selectOption('August');

    // Wait for auto-submit
    await page.waitForTimeout(1000);

    // Verify August is selected
    await expect(monthSelect).toHaveValue('8');

    // Stats should still be visible (no errors)
    await expect(page.getByText('Worth today')).toBeVisible();
  });

  test('handles invalid birthday dates gracefully (April 31st)', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots');
    await page.goto('/');

    // Find birthday row
    const birthdayRow = page.locator('text=Birthday').locator('..');

    // Set to April (month 4)
    const monthSelect = birthdayRow.locator('select').first();
    await monthSelect.selectOption('April');

    // Set to 31st (invalid for April)
    const daySelect = birthdayRow.locator('select').nth(1);
    await daySelect.selectOption('31');

    // Wait for auto-submit
    await page.waitForTimeout(1000);

    // Should not show error - stats should still be visible
    await expect(page.getByText('Worth today')).toBeVisible();
    await expect(page.getByText('Error in simulation')).not.toBeVisible();
  });

  test('updates stats when changing years duration', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation_2_years', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots', { limit: 365*2 }); // 2 years
    await page.goto('/');

    // Get initial Bitcoin amount
    const bitcoinText = await page.getByText(/Total:.*/).locator('..').textContent();
    const initialBtc = bitcoinText.match(/₿[\d.]+/)?.[0];

    // Change from 1 year to 2 years
    const yearsSelect = page.locator('select[name="simulation[years]"]');
    await yearsSelect.selectOption('2');

    // Wait for auto-submit and stats update
    await page.waitForTimeout(1000);
    // Verify stats have updated
    const newBitcoinText = await page.getByText(/Total:.*/).locator('..').textContent();
    const newBtc = newBitcoinText.match(/₿[\d.]+/)?.[0];

    // With more years, should have more Bitcoin accumulated
    expect(newBtc).not.toBe(initialBtc);
  });

  test('can set all events to zero and see appropriate message', async ({ page }) => {
    await appVcrInsertCassette('homepage_simulation', { allow_playback_repeats: true });
    await timecop.freeze('2025-10-27');
    await app('import_spots', { limit: 365 }); // 1 year
    await page.goto('/');

    // Get all amount inputs and set them to 0
    const amountInputs = await page.getByRole('spinbutton', { name: '' }).all();
    for (const input of amountInputs) {
      await input.clear();
      await input.fill('0');
    }

    // Wait for auto-submit
    await page.waitForTimeout(1000);

    // Stats should not be visible when all amounts are zero
    await expect(page.getByText('I would have gifted')).not.toBeVisible();
  });

});
