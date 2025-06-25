const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin, appFactories, app, turboCableConnected } = require('../support/on-rails');

test.describe('Theme', () => {
  test('should show error with wrong credentials', async ({ page }) => {
    await appVcrInsertCassette('stripe_products');
    await page.goto('/login');
    
    // Fill in wrong credentials
    await page.getByRole('textbox', { name: 'Email address' }).fill('admin@example.com');
    
    // Submit login form
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByRole('textbox', { name: 'Password' }).fill('blablapassword');
    await page.getByRole('button', { name: 'Sign in' }).click();
    // Verify error message is displayed
    await expect(page.getByText('Password is incorrect')).toBeVisible();
    
  });

  test('non-admin user cannot access admin theme pages', async ({ page }) => {
    await appVcrInsertCassette('stripe_products');
    await forceLogin(page, {
      email: 'john@example.com'
    });
    
    // Try to access admin themes page
    await page.goto('/admin/themes/1/edit');
    
    // Verify user getting access denied
    await expect(page.getByText('Admin access required')).toBeVisible();
  });
  test('admin can view and edit theme properties', async ({ page }) => {
    
    await appVcrInsertCassette('themes')
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/dashboard'
    });
    await page.goto('/');
    await expect(page.locator('.bg-base-100').first()).toHaveCSS('background-color', /rgb\(230\, 244\, 241\)/); //theme default

    // Navigate to admin themes page
    await page.goto('/admin/themes/1/edit');
    // Verify existing values
    await expect(page.locator('#input_theme_name')).toHaveValue('Dollar');
    await expect(page.locator('#input_theme_ui_name')).toHaveValue('cyberpunk');

    // Set new theme values
    await page.getByLabel('UI Name').selectOption('sunset');
    await page.getByLabel('Color base 100').fill('#112fa3');

    // Submit the form
    await page.locator('input[type="submit"]').click();

    // Verify success message
    await expect(page.getByText('Theme was successfully updated')).toBeVisible();

    await page.goto('/');
    await expect(page.locator('.bg-base-100').first()).toHaveCSS('background-color', /rgb\(17\, 47\, 163\)/);
  });


  test.afterEach(async ({ page }) => {
  });
});