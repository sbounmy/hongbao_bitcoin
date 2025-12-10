import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, fillCheckout } from '../support/on-rails';

test.describe('Stripe Checkout Flow', () => {

  test('logged in user can buy tokens', async ({ page }) => {
    test.setTimeout(60_000); // 40s for CI

    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'satoshi@example.com',
      redirect_to: '/tokens'
    });

    await expect(page.locator('header .badge')).toContainText('490 ₿ao', { timeout: 5_000 }); // purchased Bao + 5 free credits  });
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();


    // Verify redirect to Stripe Checkout
    await page.waitForURL('https://checkout.stripe.com/**');

    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await fillCheckout(page);
    await page.click('button[type="submit"]');
    await expect(page.getByText('Processing')).toBeVisible();
    await expect(page.url()).toBe(page.url('/'));
    await expect(page.locator('header .badge')).toContainText('502 ₿ao', { timeout: 15_000 }); // 12 free credits with Mini

    await page.waitForTimeout(1_000);
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
    await appVcrEjectCassette();

    await page.goto('/orders');
    await page.getByText(/Order \#\d+/).first().click();
    await expect(page.locator('body')).toContainText('+33651234567'); // phone number
  });

  test('admin user can buy tokens with coupon', async ({ page }) => {
    test.setTimeout(60_000); // 60s for CI

    await appVcrInsertCassette('stripe_checkout_coupon', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'admin@example.com'
    });

    await page.locator('label:has-text("Mini Pack")').click();
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();


    // Verify redirect to Stripe Checkout
    await page.waitForURL('https://checkout.stripe.com/**', { timeout: 15_000 });

    await expect(page.locator('#promotionCode')).toBeVisible({ timeout: 10_000 });
    await page.getByLabel('Add promotion code').pressSequentially('FIAT0');
    await page.getByText('Apply').click();
    await fillCheckout(page);
    await page.getByRole('button', { name: 'Complete order' }).click();
    await expect(page.getByText('Processing')).toBeVisible();
    await expect(page.url()).toBe(page.url('/'));
    await page.waitForTimeout(5_000) // wait stripe callback
    await expect(page.locator('header  .badge')).toContainText('12 ₿ao'); // 12 free credits with Mini

    // Navigate to tokens page with relaxed wait condition
    await page.goto('/tokens', { waitUntil: 'domcontentloaded', timeout: 30000 });

    // Wait for the billing button to be visible before interacting
    const billingButton = page.getByRole('button', { name: 'Manage Billing' });
    await expect(billingButton).toBeVisible({ timeout: 10000 });

    // Scroll the Manage Billing button into view
    await billingButton.scrollIntoViewIfNeeded();
    await expect(billingButton).toBeVisible();
    await expect(billingButton).toBeEnabled();
    await billingButton.click();

    await page.waitForURL('https://billing.stripe.com/p/session/**');
    // await page.waitForLoadState('networkidle', { timeout: 120000 }); // 120 seconds timeout

    await expect(page.locator('body')).toContainText("Invoice history");
    await appVcrEjectCassette();
  });

  test('logged in user can buy envelopes', async ({ page }) => {
    test.setTimeout(60_000); // 60s for CI
    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    await expect(page.locator('header .badge')).toContainText('490 ₿ao', { timeout: 5_000 }); // purchased Bao + 5 free credits  });
    // Find and click the starter plan
    await page.locator('label').filter({ hasText: /Family Pack/ }).click();
    await page.waitForTimeout(1_000); // wait for the label to be clicked
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();
    // await page.getByRole('button', { name: 'Select' }).click();

    await page.waitForTimeout(1_000); // wait for page to load
    // Verify redirect to Stripe Checkout
    await page.waitForURL('https://checkout.stripe.com/**');

    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await fillCheckout(page);
    await page.click('button[type="submit"]');
    await expect(page.getByText('Processing')).toBeVisible();
    await expect(page.url()).toBe(page.url('/'));
    await expect(page.locator('header .badge')).toContainText('514 ₿ao', { timeout: 20_000 }); // 24 credits with Family
    await page.waitForTimeout(1_000);
    await page.locator('.drawer').click();
    await expect(page.locator('.drawer').getByRole('button', { name: 'Logout' })).toBeVisible();
    await appVcrEjectCassette();
  });
});
