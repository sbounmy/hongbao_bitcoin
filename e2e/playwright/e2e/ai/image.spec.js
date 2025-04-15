import { test, expect } from '@playwright/test';
import { forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test.describe("Image generation feature", () => {

  test('User can generate new designs', async ({ page }) => {
    appVcrInsertCassette('ai_images', { record: 'new_episodes' })

    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com',
      password: '03/01/2009'
    });

    // Verify successful login
    await page.goto('/');

    // Test AI Design access
    await page.getByRole('button', { name: 'AI Design' }).click();

    await expect(page.getByText('Processing...')).toBeHidden();
    // Initiate image generation
    await page.getByText('Generate Designs (3 credits)').click();
    // Verify face swap process started
    await expect(page.getByText('Processing...')).toBeVisible();
    await appVcrEjectCassette();
  });

});