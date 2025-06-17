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

  test('admin can edit theme elements', async ({ page }) => {
    await appVcrInsertCassette('bundle', { serialize_with: 'compressed', allow_playback_repeats: true })
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/dashboard'
    });

    await page.goto('/admin/themes/1/edit');
    await page.locator('[name="input_theme[ai][public_address_qrcode][x]"]').fill('0.33');
    await page.locator('input[type="submit"]').click();
    await expect(page.getByText('Theme was successfully updated')).toBeVisible();

    await page.goto('/dashboard')
    // Select styles
    await page.getByText('Ghibli').filter({ visible: true }).first().click({ force: true });
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true }); // uncheck Marvel

    // Upload image
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await turboCableConnected(page);

    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();

    await expect(page.locator('#main-content .papers-item-component')).toHaveCount(2)
    await app('perform_jobs');
    await expect(page.locator('#main-content .papers-item-component .bg-cover')).toHaveCount(4); // 2 papers, 2 faces
    const printPromise = page.waitForEvent('popup'); // https://playwright.dev/docs/pages#handling-popups
    await page.locator('#main-content .papers-item-component').first().click()
    const print = await printPromise;
    await expect(print.locator('.canva-item[data-canva-item-name-value="publicAddressQrcode"]')).toHaveAttribute('data-canva-item-x-value', "0.33")
  });

  test.afterEach(async ({ page }) => {
  });
});