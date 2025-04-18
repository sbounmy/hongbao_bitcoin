import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('PDF Generation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/papers/1');
  });

  test('should generate PDF with correct layout and content', async ({ page }) => {
    // Wait for PDF preview to be visible
    await expect(page.locator('[data-pdf-target="content"]')).toBeVisible();

    // Check main sections
    await expect(page.getByText('SLIP INSIDE THE HONG₿AO ENVELOPE')).toBeVisible();
    await expect(page.getByText('ABOUT BITCOIN')).toBeVisible();
    await expect(page.getByText('HOW IT WORKS')).toBeVisible();
  });

  test('should handle PDF download', async ({ page, context }) => {
    // Start waiting for download before clicking
    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Next' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();
    await expect(page.getByText('Choose your preferred way to send bitcoin to this address')).toBeVisible();
  });
});