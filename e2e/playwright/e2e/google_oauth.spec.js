import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';


test.describe("Google OAuth Flow", () => {

  test("allows a new user to sign up via Google callback", async ({ page }) => {
    await appVcrInsertCassette('google_oauth', { allow_playback_repeats: true });
    await page.goto('/signup');
    await page.getByText('Sign in with Google').click();
    await expect(page.locator('body')).toContainText('to continue to HongBao Bitcoin');

    // todo: Interaction with Live Google OAuth ---
    // We should create a fake google account and use it for this test
  });
});