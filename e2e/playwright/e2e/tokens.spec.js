import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('Tokens Page', () => {
  // TODO: Add beforeEach for login if needed for all tests

  test.describe('when logged in', () => {
    test.beforeEach(async ({ page }) => {
      await appVcrInsertCassette('tokens', { allow_playback_repeats: true });
      await forceLogin(page, {
        email: 'satoshi@example.com',
        redirect_to: '/tokens'
      });
    });

    test('displays token balance', async ({ page }) => {
      await expect(page.getByText('Token Balance')).toBeVisible();
    });

    test('displays token transaction history section', async ({ page }) => {
      await expect(page.locator('div.overflow-x-auto').first()).toBeVisible();
      await expect(page.getByText('-10')).toBeVisible();
      await expect(page.getByText('Purchase')).toBeVisible();
      await expect(page.getByText('500')).toBeVisible();
      await expect(page.getByText('Genesis block')).toBeVisible();
    });

    test('allows managing card via Stripe Billing Portal', async ({ page }) => {
      // Scenario 1: Manage Card (Live Interaction)
      await expect(page.getByRole('button', { name: 'Manage Billing' })).toBeVisible();
      await page.getByRole('button', { name: 'Manage Billing' }).click();
      await page.waitForURL('https://billing.stripe.com/p/session/**');
      expect(page.url()).toContain('billing.stripe.com');

    });

    test('allows purchasing tokens via Stripe Checkout', async ({ page }) => {
        await page.getByRole('button', { name: 'Select' }).first().click();
        await page.waitForURL('https://checkout.stripe.com/c/pay/**');

        // --- Interaction with Live Stripe Checkout ---
        // !! This part relies on Stripe's Checkout UI structure !!
        // Using helper similar to checkout.spec.js, but assuming live interaction
        await expect(page.getByText('satoshi@example.com')).toBeVisible(); // Check if email is pre-filled
        await page.fill('input[name="cardNumber"]', '4242424242424242'); // Stripe test card
        await page.fill('input[name="cardExpiry"]', '12/2034'); // Future date
        await page.fill('input[name="cardCvc"]', '123');
        await page.fill('input[name="billingName"]', 'Satoshi Nakamoto Test');
        await page.selectOption('select[name="billingCountry"]', 'US'); // Use value 'US' for United States
        await page.fill('input[name="billingPostalCode"]', '94107'); // Example postal code
        await page.click('button[type="submit"]');

        await page.getByText('Processing...').waitFor({ state: 'hidden' });

        await page.goto('/tokens');
        await expect(page.locator('header').getByText('500 ₿ao')).toBeVisible(); // General check for balance display
      });

  });

  // TODO: Add tests for logged-out state if necessary
});