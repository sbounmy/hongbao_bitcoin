import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, fillCheckout } from '../support/on-rails';

test.describe('Stripe Checkout Flow', () => {

  test('logged in user can buy tokens', async ({ page }) => {

    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    await expect(page.locator('header .badge')).toContainText('490 ₿ao', { timeout: 5_000 }); // purchased Bao + 5 free credits  });
    // Find and click the starter plan
    await page.goto('/tokens');
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    await page.getByRole('button', { name: 'Buy now' }).click();


    // Verify redirect to Stripe Checkout
    await expect(page.url()).toContain('checkout.stripe.com');

    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await fillCheckout(page);
    await page.click('button[type="submit"]');
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.locator('header .badge')).toContainText('502 ₿ao', { timeout: 10_000 }); // 12 free credits with Mini
    await page.waitForTimeout(1_000);
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('admin user can buy tokens with coupon', async ({ page }) => {
    await appVcrInsertCassette('stripe_checkout_coupon', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'admin@example.com'
    });

    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    await page.getByRole('button', { name: 'Buy now' }).click();

    // Verify redirect to Stripe Checkout
    await expect(page.url()).toContain('checkout.stripe.com');

    await expect(page.getByLabel('Add promotion code')).toBeVisible();
    await page.getByLabel('Add promotion code').pressSequentially('FIAT0');
    await page.getByText('Apply').click();
    await fillCheckout(page);
    await page.getByRole('button', { name: 'Complete order' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.url()).toBe(page.url('/'));
    await expect(page.locator('header')).toContainText('12 ₿ao'); // 12 free credits with Mini

    await page.goto('/tokens');
    await page.getByRole('button', { name: 'Manage Billing' }).click();
    await page.waitForURL('https://billing.stripe.com/p/session/**');
    await expect(page.locator('body')).toContainText("Invoice history");
  });

  test('logged in user can buy envelopes', async ({ page }) => {

    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    await expect(page.locator('header .badge')).toContainText('490 ₿ao', { timeout: 5_000 }); // purchased Bao + 5 free credits  });
    // Find and click the starter plan
    await page.locator('label').filter({ hasText: /Family Pack/ }).click();
    await page.getByRole('button', { name: 'Buy now' }).click();
    // await page.getByRole('button', { name: 'Select' }).click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await fillCheckout(page);
    await page.click('button[type="submit"]');
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.locator('header .badge')).toContainText('514 ₿ao', { timeout: 10_000 }); // 24 credits with Family
    await page.waitForTimeout(1_000);
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });
});
