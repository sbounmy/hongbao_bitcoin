import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';


test.describe("Input Events", () => {

  test("shows a bitcoin major event", async ({ page }) => {
    await page.goto('/inputs/15');
    await expect(page.locator('body')).toContainText('Pizza Day');
    await expect(page.locator('body')).toContainText('May 22, 2010');
    await expect(page.locator('body')).toContainText("Celebrates the very first \'real world\'");
    await expect(page.locator('.papers-item-component')).toHaveCount(1);
  });
});