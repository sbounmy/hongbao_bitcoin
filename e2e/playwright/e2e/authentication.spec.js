import { test, expect } from '@playwright/test';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/signup');
  });

  test('existing user can login', async ({ page }) => {
    await page.getByPlaceholder('Email address').fill('satoshi@example.com');
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByPlaceholder('Password').fill('03/01/2009');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.getByText('Make every Bitcoin')).toBeVisible();
    await page.goto('/v2'); // TODO: remove this when /v2 becomes /
    await expect(page.getByText('Logout')).toBeVisible();
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
    await expect(page.getByText('Make every Bitcoin')).toBeVisible();
    await page.goto('/v2'); // TODO: remove this when /v2 becomes /
    await expect(page.getByText('Logout')).toBeVisible();
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

});