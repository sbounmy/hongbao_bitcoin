import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, fillCheckout, appVcrInsertCassette } from '../support/on-rails';

test.describe('Tokens Page', () => {
  const userEmail = 'satoshi@example.com';

  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('tokens');
    // We log in with a consistent user. The webhook filtering logic, using
    // client_reference_id, will handle race conditions during parallel test runs.
    await forceLogin(page, {
      email: userEmail,
      redirect_to: '/tokens'
    });
  });

  test('displays token balance', async ({ page }) => {
    await expect(page.getByText('Token Balance')).toBeVisible();
  });

  test('displays token transaction history section', async ({ page }) => {
    await expect(page.locator('div.overflow-x-auto').first()).toBeVisible();
    // With a consistent user who has a history from fixtures.
    await expect(page.getByText('Genesis block')).toBeVisible();
  });

  test('allows managing card via Stripe Billing Portal', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Manage Billing' })).toBeVisible();
    await page.getByRole('button', { name: 'Manage Billing' }).click();
    await page.waitForURL('https://billing.stripe.com/p/session/**');
    expect(page.url()).toContain('billing.stripe.com');
  });

  test('allows purchasing tokens via Stripe Checkout', async ({ page }) => {
    await page.locator('label').filter({ hasText: /Family Pack/ }).click();
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();

    await page.waitForURL('https://checkout.stripe.com/c/pay/**');

    await expect(page.getByText(userEmail)).toBeVisible();
    await fillCheckout(page);
    await page.click('button[type="submit"]');

    await page.getByText('Processing...').waitFor({ state: 'hidden' });

    await page.goto('/tokens');
    // The user starts with 490 (from fixture) and buys 24 tokens
    await expect(page.locator('header')).toContainText('514 ₿ao');
  });
});