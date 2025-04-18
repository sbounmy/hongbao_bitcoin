import { test, expect } from '../../support/test-setup';
import { app, appScenario } from '../../support/on-rails';

test.describe("Rails using scenarios examples", () => {

  test("setup basic scenario", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('.sticky').getByText('Hong₿ao')).toBeVisible();
  });
});
