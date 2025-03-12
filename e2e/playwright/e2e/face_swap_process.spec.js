import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://salma.hongbaob.tc/login');
  await page.getByRole('textbox', { name: 'Email address' }).click();
  await page.getByRole('textbox', { name: 'Email address' }).fill('example@gmail.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('123456789');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.getByRole('button', { name: 'AI Design' }).click();
  await page.getByText('AI Generated A Christmas').nth(1).click();
  await page.locator('#image').click();
  await page.locator('#image').setInputFiles('B9732896669Z.1_20221208193243_000+GIKLR0J0J.1-0.jpg');
  await page.getByRole('button', { name: 'Face Swap' }).click();
});