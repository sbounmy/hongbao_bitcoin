import { test, expect } from '../support/test-setup';

test.describe('Static pages', () => {
  test('user can watch satoshi mystery video', async ({ page }) => {
    await page.goto('/satoshi');
    await expect(page.locator('iframe')).toBeVisible();
    await expect(page.locator('iframe')).toHaveAttribute('src', 'https://drive.google.com/file/d/1SkxgeFFKGZfsk4ro7GwGhPJz8pJio7QP/preview');
  });
});