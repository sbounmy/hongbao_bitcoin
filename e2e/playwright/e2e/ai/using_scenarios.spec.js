import { test, expect } from '../../support/test-setup';
import { app, appScenario, appVcrInsertCassette } from '../../support/on-rails';

test.describe("Rails using scenarios examples", () => {

  test("setup basic scenario", async ({ page }) => {
    await appVcrInsertCassette('basic_scenario')
    await page.goto("/");
    await expect(page.locator('header').getByText('Hong₿ao')).toBeVisible();
  });
});
