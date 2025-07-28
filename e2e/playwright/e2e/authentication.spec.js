import { test, expect } from '../support/test-setup';
import { forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('Authentication Flow', () => {

  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('authentication', { allow_playback_repeats: true });
    await page.goto('/signup');
  });

  test('existing user can login', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('satoshi@example.com');
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByPlaceholder('Password').fill('03/01/2009');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.locator('.drawer')).toBeVisible();
    await page.waitForTimeout(1_000); // Wait for drawer to load fix flakyness
    await page.locator('.drawer').click();
    await expect(page.getByText('satoshi@example.com')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('existing user type wrong password', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('satoshi@example.com');
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByPlaceholder('Password').fill('invalid.password');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.getByText('Password is incorrect')).toBeVisible();
  });

  test('new user can sign up', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('new.user@example.com');
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByPlaceholder('Password').fill('new.password');
    await page.getByRole('button', { name: 'Sign up with email' }).click();
    await expect(page.locator('.drawer')).toBeVisible();
    await page.waitForTimeout(1_000); // Wait for drawer to load fix flakyness
    await page.locator('.drawer').click();
    await expect(page.getByText('new.user@example.com')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('signup with invalid email', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('invalid.email');
    await page.getByRole('button', { name: 'Continue' }).click();
    await expect(page.getByRole('button', { name: 'Sign up with email' })).toBeHidden();
  });

  test('signup with invalid password', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('new.user@example.com');
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByPlaceholder('Password').fill('p');
    await page.getByRole('button', { name: 'Sign up with email' }).click();

    await expect(page.getByText('Password is too short')).toBeVisible();
  });

  test('user can logout', async ({ page }) => {
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });
    await page.locator('.drawer').click();
    await page.getByRole('button', { name: 'Logout' }).click();
  });
});

test.describe('Password Reset Flow', () => {
  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('password_reset', { allow_playback_repeats: true });
  });

  test.afterEach(async ({ page }) => {
    await appVcrEjectCassette();
  });

  test('user can request password reset', async ({ page }) => {
    await page.goto('/signup');

    await page.getByRole('button', { name: 'Continue' }).click();
    
    await page.getByRole('link', { name: 'Forgot password?' }).click();
    
    await expect(page).toHaveURL('/passwords/new');
    await expect(page.getByRole('heading', { name: 'Forgot your password?' })).toBeVisible();
    
    await page.getByPlaceholder('Email address').fill('satoshi@example.com');

    await page.getByRole('button', { name: 'Email reset instructions' }).click();
    
    await expect(page).toHaveURL('/login');
    await expect(page.locator('.toast .alert-success')).toBeVisible();
    await expect(page.locator('.toast .alert-success')).toContainText('Password reset instructions sent');
  });

  test('password reset with non-existent email', async ({ page }) => {
    await page.goto('/passwords/new');
    
    await page.getByPlaceholder('Enter your email address').fill('nonexistent@example.com');
    await page.getByRole('button', { name: 'Email reset instructions' }).click();
    
    await expect(page).toHaveURL('/passwords/new');
    await expect(page.locator('.toast .alert-error')).toBeVisible();
    await expect(page.locator('.toast .alert-error')).toContainText('No account found with email');
  });

  test('user can navigate back to sign in from password reset', async ({ page }) => {
    await page.goto('/passwords/new');
    
    await page.getByRole('link', { name: 'Back to sign in' }).click();
    
    await expect(page).toHaveURL('/login');
  });

  test('password reset form validation', async ({ page }) => {
    await page.goto('/passwords/new');
    
    await page.getByPlaceholder('Enter your email address').fill('');
    await page.getByRole('button', { name: 'Email reset instructions' }).click();
    
    await expect(page).toHaveURL('/passwords/new');
  });
  
  test('expired or invalid password reset token shows error', async ({ page }) => {
    // Test with an obviously invalid token
    await page.goto('/passwords/invalid-token-12345/edit');
    
    await expect(page).toHaveURL('/passwords/new');
    await expect(page.locator('.toast .alert-error')).toBeVisible();
    await expect(page.locator('.toast .alert-error')).toContainText('Password reset link is invalid or has expired');
  });
});

test.describe('Protected Routes', () => {
  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('authentication', { allow_playback_repeats: true });
  });

  test.afterEach(async ({ page }) => {
    await appVcrEjectCassette();
  });

  test('redirects unauthenticated users to signup', async ({ page }) => {
    await page.goto('/orders');
    await expect(page).toHaveURL('/signup');
    
    await page.goto('/tokens');
    await expect(page).toHaveURL('/signup');
  });

  test('authenticated users can access protected routes', async ({ page }) => {
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });
    
    await page.goto('/orders');
    await expect(page).toHaveURL('/orders');
    await expect(page.getByRole('heading', { name: 'My Orders' })).toBeVisible();
    
    await page.goto('/tokens');
    await expect(page).toHaveURL('/tokens');
  });
});