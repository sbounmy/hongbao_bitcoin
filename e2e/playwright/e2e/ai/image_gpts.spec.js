import { test, expect } from '../../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test.describe("Generate image gpts feature", () => {

  test('user can generate image gpts from a picture based on style(s)', async ({ page }) => {
    await appVcrInsertCassette('ai_image_gpts', { allow_playback_repeats: true })
    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    // Select styles
    await page.getByText('Ghibli').filter({ visible: true }).first().click({ force: true });
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });



    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    const count = await page.locator('#main-content .papers-item-component').count();

    // Clear potential errors from previous actions if any
    await expect(page.locator('#image-gpt-errors')).toHaveText('');

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();
    // TODO: This success check should ideally wait for a turbo stream update
    // instead of a full page navigation, once success handling is implemented.
    await page.goto('/');
    await expect(page.locator('#main-content .papers-item-component')).toHaveCount(count + 2);
  });

  test('show error when no styles are selected', async ({ page }) => {
    await appVcrInsertCassette('ai_image_gpts', { allow_playback_repeats: true })
    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await expect(page.getByText('Processing...')).toBeHidden();
    // Click generate without selecting styles
    await page.getByRole('button', { name: 'Generate' }).click();

    // Check for the error message within the specific div
    await expect(page.locator('body')).toHaveText('Please select at least one style');
  });
});
