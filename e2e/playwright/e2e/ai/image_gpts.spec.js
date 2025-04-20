import { test, expect } from '../../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../../support/on-rails';

test.describe("Generate image gpts feature", () => {

  test('user can generate image gpts from a picture based on style(s)', async ({ page }) => {
    await appVcrInsertCassette('ai_image_gpts')
    // Force login the user
    await forceLogin(page, {
      email: 'satoshi@example.com',
      redirect_to: '/v2'
    });

    // Select styles
    await page.getByText('Ghibli').filter({ visible: true }).first().click({ force: true });
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true });



    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    const count = await page.locator('#main-content .papers-item-component').count();

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();
    // this should be done through turbo frame
    await page.goto('/v2');
    await expect(page.locator('#main-content .papers-item-component')).toHaveCount(count + 2);
  });

});