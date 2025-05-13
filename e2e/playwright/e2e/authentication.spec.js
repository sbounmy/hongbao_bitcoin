import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

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
    await page.getByLabel('user-drawer-toggle').click();
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
    await page.locator('.drawer').click();
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