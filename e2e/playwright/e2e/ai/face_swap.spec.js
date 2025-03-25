import { test, expect } from '@playwright/test';

test('user can sign up and access AI Design features', async ({ page }) => {
  // Start signup process
  await page.goto('/signup');

  // Fill in signup form
  await page.getByRole('textbox', { name: 'Email address' }).fill('example@gmail.com');
  await page.getByRole('textbox', { name: 'Password' }).fill('123456789');
  await page.getByRole('textbox', { name: 'Password Confirmation' }).fill('123456789');

  // Submit signup form
  await page.getByRole('button', { name: 'Sign up' }).click();

  // Verify successful signup
  await expect(page).toHaveURL('/');
  await expect(page.getByText('Welcome! You have signed up successfully.')).toBeVisible();

  // Test AI Design access
  await page.getByRole('button', { name: 'AI Design' }).click();
  await expect(page).toHaveURL('/ai_designs');

  // Select Christmas design and upload image
  await page.getByText('AI Generated A Christmas').nth(1).click();
  await page.locator('#image').setInputFiles('B9732896669Z.1_20221208193243_000+GIKLR0J0J.1-0.jpg');

  // Initiate face swap
  await page.getByRole('button', { name: 'Face Swap' }).click();

  // Verify face swap process started
  await expect(page.getByText('Processing your image')).toBeVisible();
});