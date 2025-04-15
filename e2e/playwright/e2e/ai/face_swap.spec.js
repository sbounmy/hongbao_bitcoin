import { test, expect } from '@playwright/test';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test.describe("Face swap feature", () => {

  test('user can swap their face with an image ', async ({ page }) => {
    await appVcrInsertCassette('ai_face_swap')
    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com',
      password: '03/01/2009'
    });
    // Verify successful login
    await page.goto('/');
    // Test AI Design access
    await page.getByRole('button', { name: 'AI Design' }).click();

    await page.locator('#ai_designs_results').getByText('Dollar').filter({ visible: true }).first().click({ force: true });

    await page.locator('#ai_image_occasion').selectOption('Dollar');
    // Select Christmas design and upload image
    await page.locator('#ai_face_swap_image').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await expect(page.getByText('Processing...')).toBeHidden();
    // Initiate face swap
    await page.getByRole('button', { name: 'Face Swap' }).click();
    // Verify face swap process started
    await expect(page.getByText('Processing...')).toBeVisible();
  });
});