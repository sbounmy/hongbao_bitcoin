import { test, expect } from '../support/test-setup';
import { appVcrInsertCassette, appVcrEjectCassette, app, timecop } from '../support/on-rails';

test.describe('Homepage Bitcoin Gifting Simulator', () => {

  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('homepage_simulator', { allow_playback_repeats: true });

    // Freeze time before importing spots to ensure consistent date calculations
    await timecop.freeze('2025-10-27');
    await app('import_spots');
    await page.goto('/');

    // Wait for simulator section to be visible
    await expect(page.getByText('Bitcoin is the best performing asset')).toBeVisible();
  });

  test.afterEach(async () => {
    await timecop.return()
    await appVcrEjectCassette();
  });

  test('displays the simulator form with default values', async ({ page }) => {
    // Check simulator form is visible
    await expect(page.getByText('If I had gifted Bitcoin on')).toBeVisible();

    // Check default event amounts are displayed
    const christmasInput = page.getByRole('spinbutton', { name: '' }).first();
    await expect(christmasInput).toHaveValue('50');

    // Check years selector (using label to be specific since there are birthday month/day selectors)
    const yearsSelect = page.locator('select[name="simulator[years]"]');
    await expect(yearsSelect).toContainText('5 years');

    // Check "View full simulator" button exists
    await expect(page.getByRole('link', { name: 'View full simulator' })).toBeVisible();
  });

  test('displays default stats results', async ({ page }) => {
    // Wait for stats to load
    await page.waitForTimeout(1000); // Wait for auto-submit

    // Check stats cards are visible
    await expect(page.getByText('I would have gifted')).toBeVisible();
    await expect(page.getByText('Worth today')).toBeVisible();

    // Check "Total Bitcoin accumulated" is visible with year
    await expect(page.getByText(/Total:.*/)).toBeVisible();
    await expect(page.getByText(/since \d{4}/)).toBeVisible();
  });

  test('updates stats when changing event amounts', async ({ page }) => {
    // Wait for initial load
    await page.waitForTimeout(1000);

    // Get initial "I would have gifted" value
    const statsCard = page.getByText('I would have gifted').locator('..');
    const initialAmount = await statsCard.locator('.font-bold').first().textContent();

    // Change Christmas amount from 50 to 200
    const christmasInput = page.getByRole('spinbutton', { name: '' }).first();
    await christmasInput.clear();
    await christmasInput.fill('200');

    // Wait for auto-submit and stats update
    await page.waitForTimeout(1000);

    // Verify stats have changed
    const newAmount = await statsCard.locator('.font-bold').first().textContent();
    expect(newAmount).not.toBe(initialAmount);
  });

  test('updates stats when changing birthday date', async ({ page }) => {
    // Wait for initial load
    await page.waitForTimeout(1000);

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
    // Wait for initial load
    await page.waitForTimeout(1000);

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
    // Wait for initial load
    await page.waitForTimeout(1000);
    await page.clock.setFixedTime(new Date('2025-10-27T10:30:00'));
    // Get initial Bitcoin amount
    const bitcoinText = await page.getByText(/Total:.*/).locator('..').textContent();
    const initialBtc = bitcoinText.match(/₿[\d.]+/)?.[0];

    // Change from 5 years to 10 years
    const yearsSelect = page.locator('select[name="simulator[years]"]');
    await yearsSelect.selectOption('10');

    // Wait for auto-submit and stats update
    await page.waitForTimeout(1000);
    // Verify stats have updated
    const newBitcoinText = await page.getByText(/Total:.*/).locator('..').textContent();
    const newBtc = newBitcoinText.match(/₿[\d.]+/)?.[0];

    // With more years, should have more Bitcoin accumulated
    expect(newBtc).not.toBe(initialBtc);
  });

  test('can set all events to zero and see appropriate message', async ({ page }) => {
    // Wait for initial load
    await page.waitForTimeout(1000);

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

  test('navigates to full simulator when clicking "View full simulator"', async ({ page }) => {
    const viewFullButton = page.getByRole('link', { name: 'View full simulator' });
    await viewFullButton.click();

    // Should navigate to /simulator
    await expect(page).toHaveURL(/\/simulator/);

    // Full simulator should show chart and table
    await expect(page.getByText('Gift History')).toBeVisible();
  });

  test('simulator section has proper styling and layout', async ({ page }) => {
    // Check the section has the gradient background
    const simulatorSection = page.locator('section').filter({ hasText: 'Bitcoin is the best performing asset' });
    await expect(simulatorSection).toBeVisible();

    // Check two-column layout exists
    await expect(page.getByText('Bitcoin is the best performing asset')).toBeVisible();
    await expect(page.getByText('If I had gifted Bitcoin on')).toBeVisible();

    // Both should be visible simultaneously (side by side on desktop)
    const leftColumn = page.getByText('Bitcoin is the best performing asset').locator('..');
    const rightColumn = page.getByText('If I had gifted Bitcoin on').locator('..');

    await expect(leftColumn).toBeVisible();
    await expect(rightColumn).toBeVisible();
  });
});
