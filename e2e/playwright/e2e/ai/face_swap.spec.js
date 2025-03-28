import { test, expect } from '@playwright/test';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test('user can access AI Design features', async ({ page }) => {
  await app('activerecord_fixtures');
  appVcrInsertCassette('ai_designs', { record: 'new_episodes' })

  // Force login the user
  await forceLogin(page, {
    email: 'satoshi@example.com',
    password: '03/01/2009'
  });

  // Verify successful login
  await page.goto('/');

  // Test AI Design access
  await page.getByRole('button', { name: 'AI Design' }).click();


  await page.locator('#ai_designs_results').getByText('Dollar Bill').filter({ visible: true }).first().click();

  await page.locator('#ai_image_occasion').selectOption('Wedding');
  // Select Christmas design and upload image
  await page.locator('#ai_face_swap_image').setInputFiles('spec/fixtures/files/satoshi.jpg');

  // Initiate face swap
  await page.getByRole('button', { name: 'Face Swap' }).click();
  appVcrEjectCassette()
  // Verify face swap process started
  await expect(page.getByText('Processing your image')).toBeVisible();
});