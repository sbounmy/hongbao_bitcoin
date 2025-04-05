import { test, expect } from "@playwright/test";
import { app, appScenario } from '../../support/on-rails';

test.describe("Rails using scenarios examples", () => {
  test.beforeEach(async ({ page }) => {
    await app('clean');
  });

  test("setup basic scenario", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('.sticky').getByText('Hong₿ao')).toBeVisible();
  });
});
