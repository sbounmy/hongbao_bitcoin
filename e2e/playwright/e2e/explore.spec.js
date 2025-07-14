import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, fillCheckout } from '../support/on-rails';

test.describe('Explore', () => {

  test('user can explore papers', async ({ page }) => {
    await page.goto('/papers/explore');
    await expect(page.locator('body')).toContainText('Explore');
    await expect(page.locator('.papers-item-component')).toHaveCount(2);
  });
});
