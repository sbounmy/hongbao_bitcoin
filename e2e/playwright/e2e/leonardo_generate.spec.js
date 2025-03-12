import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://salma.hongbaob.tc/login');
  await page.locator('div').filter({ hasText: 'Sign in to your account Sign' }).first().click();
  await page.getByRole('textbox', { name: 'Email address' }).click();
  await page.getByRole('textbox', { name: 'Email address' }).fill('example@gmail.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('123456789');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.getByRole('button', { name: 'AI Design' }).click();
  await page.locator('#occasion').selectOption('Christmas');
  await page.getByRole('button', { name: 'Generate Designs (3 credits)' }).click();
});