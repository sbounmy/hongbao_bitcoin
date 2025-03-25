import { test, expect } from '@playwright/test';
import { app, appScenario, forceLogin } from '../../support/on-rails';
test('user can access AI Design features', async ({ page }) => {
  await app('activerecord_fixtures');
  // Force login the user

  await forceLogin(page, {
    email: 'satoshi@example.com',
    password: '03/01/2009'
  });

  // Verify successful login
  await page.goto('/');
  await expect(page).toHaveURL('/');

  // Test AI Design access
  await page.getByRole('button', { name: 'AI Design' }).click();
  await expect(page).toHaveURL('/ai_designs');

  // Select Christmas design and upload image
  await page.getByText('AI Generated A Christmas').nth(1).click();
  await page.locator('#image').setInputFiles('B9732896669Z.1_20221208193243_000+GIKLR0J0J.1-0.jpg');

  // Initiate face swap
  await page.getByRole('button', { name: 'Face Swap' }).click();

  // Verify face swap process started
  await expect(page.getByText('Processing your image')).toBeVisible();
});