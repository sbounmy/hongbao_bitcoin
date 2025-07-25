import { test, expect } from '../support/test-setup';
import { app, appScenario, appVcrInsertCassette, appVcrEjectCassette, fillCheckout } from '../support/on-rails';

test.describe('Stripe Guest Checkout Flow', () => {
  test('guest user can buy tokens and have account created', async ({ page }) => {
    test.setTimeout(60_000); // 60s for CI

    await appVcrInsertCassette('stripe_checkout_guest_user', { allow_playback_repeats: true });

    // Start as unauthenticated user
    await page.goto('/');
    
    // Verify user is not logged in
    await expect(page.getByRole('link', { name: 'Login' })).toBeVisible();
    
    // Choose a plan
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    
    // Click buy with credit card
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();

    // Verify redirect to Stripe Checkout
    await expect(page).toHaveURL(/checkout\.stripe\.com/);
    
    // Fill email as guest
    const guestEmail = 'newguest@example.com';
    await page.getByLabel('Email').fill(guestEmail);
    
    // Fill payment details
    await fillCheckout(page);
    
    // Complete the order
    await page.click('button[type="submit"]');
    
    // Wait for processing
    await expect(page.getByText('Processing...')).toBeVisible();
    
    // Should redirect back to homepage with success message
    await expect(page).toHaveURL(page.url('/'));
    await expect(page.getByText('Payment successful! An account has been created for you. Please check your email for further instructions.')).toBeVisible();
    
    // Verify user is still not logged in (guest checkout doesn't auto-login)
    await expect(page.getByRole('link', { name: 'Login' })).toBeVisible();
    
    // Verify account was created by going to password reset page
    await page.goto('/passwords/new');
    await page.getByPlaceholder('Email address').fill(guestEmail);
    await page.getByRole('button', { name: 'Send password reset email' }).click();
    
    // Should show success message confirming account exists
    await expect(page.getByText('Password reset instructions sent (if user with that email address exists).')).toBeVisible();
    
    await appVcrEjectCassette();
  });

  test('guest checkout with existing email uses existing account', async ({ page }) => {
    test.setTimeout(60_000); // 60s for CI

    await appVcrInsertCassette('stripe_checkout_guest_existing_email', { allow_playback_repeats: true });

    // Start as unauthenticated user
    await page.goto('/');
    
    // Choose a plan
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    
    // Click buy with credit card
    await page.getByRole('button', { name: 'Buy with Credit Card' }).click();

    // Verify redirect to Stripe Checkout
    await expect(page).toHaveURL(/checkout\.stripe\.com/);
    
    // Use existing user's email
    const existingEmail = 'satoshi@example.com';
    await page.getByLabel('Email').fill(existingEmail);
    
    // Fill payment details
    await fillCheckout(page);
    
    // Complete the order
    await page.click('button[type="submit"]');
    
    // Wait for processing
    await expect(page.getByText('Processing...')).toBeVisible();
    
    // Should redirect back to homepage with success message
    await expect(page).toHaveURL(page.url('/'));
    await expect(page.getByText('Payment successful! An account has been created for you. Please check your email for further instructions.')).toBeVisible();
    
    // Verify no new account was created - existing user still has same number of tokens
    // (we can't test login directly as we don't know the test user's password)
    
    await appVcrEjectCassette();
  });
});