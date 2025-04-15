import { test, expect } from '@playwright/test';
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
    await page.goto('/v2');

    // Find and click the starter plan
    await page.getByRole('button', { name: 'Select' }).first().click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    const random = getRandomInt(9999);
    await checkout(page, `hongbaob+${random}@example.com`);
    // expect(page.getByText('Processing...')).toBeHidden({ timeout: 5_000 });
    // expect(page.url()).toBe(page.url('/'));
    await page.waitForTimeout(5_000);
    await expect(page.url()).toBe(page.url('/v2'));
    await expect(page.getByText('Logout')).toBeVisible(); // create user if necessary and logs him in
    await expect(page.locator('header').getByText("5 ₿ao")).toBeVisible(); // purchased Bao + 5 free credits
  });

  test('logged out user can buy tokens and become logged inas a user', async ({ page }) => {
    // Insert VCR cassette for Stripe API calls
    await appVcrInsertCassette('stripe_checkout_existing_user', { allow_playback_repeats: true });
    await page.goto('/v2');

    // Find and click the starter plan
    await page.getByRole('button', { name: 'Select' }).first().click();

    // Verify redirect to Stripe Checkout
    expect(page.url()).toContain('checkout.stripe.com');

    const random = getRandomInt(9999);
    await checkout(page, `satoshi@example.com`);
    // expect(page.getByText('Processing...')).toBeHidden({ timeout: 5_000 });
    await page.waitForTimeout(5_000);
    await expect(page.url()).toBe(page.url('/v2'));
    await expect(page.getByText('Logout')).toBeVisible(); // create user if necessary and logs him in
    await expect(page.locator('header').getByText("500 ₿ao")).toBeVisible(); // purchased Bao + 5 free credits
  });

  test('logged in user can buy tokens', async ({ page }) => {

    await forceLogin(page, {
      email: 'satoshi@example.com',
      password: '03/01/2009'
    });

    // Insert VCR cassette for Stripe API calls
    await appVcrInsertCassette('stripe_checkout_existing_user_logged_in', { allow_playback_repeats: true });
    await page.goto('/v2');
    await expect(page.locator('header').getByText("490 ₿ao")).toBeVisible();
    // Find and click the starter plan
    await page.getByRole('button', { name: 'Select' }).first().click();

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
    // expect(page.getByText('Processing...')).toBeHidden({ timeout: 5_000 });
    await page.waitForTimeout(5_000);
    await expect(page.url()).toBe(page.url('/v2'));
    await expect(page.getByText('Logout')).toBeVisible(); // create user if necessary and logs him in
    await expect(page.locator('header').getByText("500 ₿ao")).toBeVisible(); // purchased Bao + 5 free credits  });
  });
});
