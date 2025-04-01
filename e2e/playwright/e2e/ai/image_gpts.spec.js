import { test, expect } from '@playwright/test';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test.describe("Generate image gpts feature", () => {

  test('user can generate image gpts from a picture based on style(s)', async ({ page }) => {
    appVcrInsertCassette('ai_image_gpts')
    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com',
      password: '03/01/2009'
    });
    // Verify successful login
    await page.goto('/v2');
    // Test AI Design access
    await page.getByRole('button', { name: 'AI Design' }).click();

    // click on ghibli
    await page.getByText('Ghibli').filter({ visible: true }).first().click({ force: true });
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });



    // Select Christmas design and upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    // Verify face swap process started
    await expect(page.locator('.papers-item-component').count()).toBe(2);
  });

});