const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin, appFactories } = require('../support/on-rails');

test.describe('Theme', () => {

  test.beforeEach(async ({ page }) => {
    // Create admin user and authenticate
    await appVcrInsertCassette('themes')
    await forceLogin(page, {
      email: 'satoshi@example.com'
    });
  });

  const hexToRgb = hex =>
    hex.replace(/^#?([a-f\d])([a-f\d])([a-f\d])$/i
               ,(m, r, g, b) => '#' + r + r + g + g + b + b)
      .substring(1).match(/.{2}/g)
      .map(x => parseInt(x, 16))

  test('admin can view and edit theme properties', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('.bg-base-100').first()).toHaveCSS('background-color', 'oklch(0.9451 0.179 104.32)'); //theme default

    // Navigate to admin themes page
    await page.setExtraHTTPHeaders({
      Authorization: 'Basic '+btoa('satoshiisalive:this-is-just-a-test')
   })
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
    await page.setExtraHTTPHeaders({
      Authorization: 'Basic ' + btoa('satoshiisalive:this-is-just-a-test')
    })
    await page.goto('/admin/themes/1/edit');
    await page.locator('[name="input_theme[ai][public_address_qrcode][x]"]').fill('0.33');
    await page.locator('input[type="submit"]').click();
    await expect(page.getByText('Theme was successfully updated')).toBeVisible();
    await page.goto('/papers/1')
    // <div data-controller="canva-item" data-canva-target="canvaItem" data-canva-item-x-value="0.82" data-canva-item-y-value="0.285" data-canva-item-name-value="privateKeyQrcode" data-canva-item-type-value="image" data-canva-item-font-size-value="0.09" data-canva-item-font-color-value="#000000" data-canva-item-max-text-width-value="0" class="hidden canva-item"></div>
    await expect(page.locator('.canva-item[data-canva-item-name-value="publicAddressQrcode"]')).toHaveAttribute('data-canva-item-x-value', "0.33")
  });

});