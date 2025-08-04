import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';


test.describe("Input Themes", () => {

  test("shows papers related to a theme", async ({ page }) => {
    await page.goto('/inputs/1'); // dollar
    await expect(page.locator('body')).toContainText('Dollar');
    await expect(page.locator('.papers-item-component')).toHaveCount(1);
    await page.goto('/inputs/2'); // euro
    await expect(page.locator('body')).toContainText('Euro');
    await expect(page.locator('.papers-item-component')).toHaveCount(0);
  });
});