import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

async function checkout(page, email) {
  await page.fill('input[name="email"]', email);
  await page.fill('input[name="cardNumber"]', '4242424242424242');
  await page.fill('input[name="cardExpiry"]', '12/2034');
  await page.fill('input[name="cardCvc"]', '123');
  await page.fill('input[name="billingName"]', email.split('@')[0]);
  await page.selectOption('select[name="billingCountry"]', 'United States');
  await page.fill('input[name="billingPostalCode"]', '12345');
  await page.click('button[type="submit"]');
  await expect(page.getByText('Processing...')).toBeVisible();
}
test.describe('Stripe Checkout Flow', () => {

  test('visitor can buy tokens and become signed up as a user', async ({ page }) => {
    // Insert VCR cassette for Stripe API calls
    await appVcrInsertCassette('stripe_checkout', { allow_playback_repeats: true });
    await page.goto('/');

    // Find and click the starter plan
    await page.getByRole('button', { name: 'Select' }).first().click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    const random = getRandomInt(9999);
    await checkout(page, `hongbaob+${random}@example.com`);
    // expect(page.getByText('Processing...')).toBeHidden({ timeout: 5_000 });
    // expect(page.url()).toBe(page.url('/'));
    await expect(page.locator('header .badge')).toContainText('5 ₿ao', { timeout: 10_000 }); // purchased Bao + 5 free credits
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('logged out user can buy tokens and become logged inas a user', async ({ page }) => {
    // Insert VCR cassette for Stripe API calls
    await appVcrInsertCassette('stripe_checkout_existing_user', { allow_playback_repeats: true });
    await page.goto('/');

    // Find and click the starter plan
    await page.getByText(/^5 ₿ao$/).locator('..').getByRole('button', { name: 'Select' }).click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    const random = getRandomInt(9999);
    await checkout(page, `satoshi@example.com`);
    // expect(page.getByText('Processing...')).toBeHidden({ timeout: 5_000 });

    await expect(page.locator('header .badge')).toContainText('495 ₿ao', { timeout: 10_000 }); // purchased Bao + 5 free credits
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('logged in user can buy tokens', async ({ page }) => {

    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'satoshi@example.com'
    });

    await expect(page.locator('header .badge')).toContainText('490 ₿ao', { timeout: 5_000 }); // purchased Bao + 5 free credits  });
    // Find and click the starter plan
    await page.getByText(/^5 ₿ao$/).locator('..').getByRole('button', { name: 'Select' }).click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    const random = getRandomInt(9999);
    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await page.fill('input[name="cardNumber"]', '4242424242424242');
    await page.fill('input[name="cardExpiry"]', '12/2034');
    await page.fill('input[name="cardCvc"]', '123');
    await page.fill('input[name="billingName"]', `Satoshi Nakamoto ${random}`);
    await page.selectOption('select[name="billingCountry"]', 'United States');
    await page.fill('input[name="billingPostalCode"]', '12345');
    await page.click('button[type="submit"]');
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.locator('header .badge')).toContainText('495 ₿ao', { timeout: 10_000 }); // purchased Bao + 5 free credits  });
    await page.locator('.drawer').click();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('admin user can buy tokens with coupon', async ({ page }) => {
    await appVcrInsertCassette('stripe_checkout_coupon', { allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'admin@example.com'
    });

    await page.getByRole('button', { name: 'Select' }).first().click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    expect(page.getByLabel('Add promotion code')).toBeVisible();
    await page.getByLabel('Add promotion code').fill('BITCOIN_FOOD');
    await page.getByText('Apply').click();
    await page.getByRole('button', { name: 'Complete order' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.url()).toBe(page.url('/'));
    await expect(page.locator('header')).toContainText('5 ₿ao'); // purchased Bao + 5 free credits

    await page.goto('/tokens');
    await page.getByRole('button', { name: 'Manage Billing' }).click();
    await page.waitForURL('https://billing.stripe.com/p/session/**');
    await expect(page.locator('body')).toContainText("Invoice history");
  });
});
