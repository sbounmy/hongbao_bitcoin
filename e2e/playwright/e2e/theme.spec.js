const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin, appFactories, app, turboCableConnected } = require('../support/on-rails');


async function drag(page, locator, { dx, dy }) {
  const box = await locator.boundingBox();
  if (!box) {
    throw new Error('Locator for drag not found or not visible.');
  }
  await locator.dragTo(locator, {
    // Start drag from the center of the element
    sourcePosition: { x: box.width / 2, y: box.height / 2 },
    // Drag to a position offset by dx, dy from the center
    targetPosition: { x: box.width / 2 + dx, y: box.height / 2 + dy },
    // Use force to avoid issues with other elements blocking the drag
    force: true
  });
}


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
    test.skip('for the moment too complicate to maintain style per theme on homepage/dashboard');
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

  test('admin can edit theme elements via visual editor', async ({ page }) => {
    await appVcrInsertCassette('bundle', { serialize_with: 'compressed', allow_playback_repeats: true });

    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/themes/1/edit'
    });

    // Locate element, canvas, and corresponding hidden inputs
    const element = page.locator('[data-element-type="public_address_qrcode"]').first();
    const xInput = page.locator('input[name="input_theme[ai][public_address_qrcode][x]"]');
    const yInput = page.locator('input[name="input_theme[ai][public_address_qrcode][y]"]');
    const canvas = page.locator('[data-visual-editor-target="canvas"]');

    // Wait for the image inside the canvas to be loaded and stable
    await expect(page.locator('[data-visual-editor-target="frontImage"]')).toBeVisible();
    await page.waitForLoadState('networkidle');

    // Get initial coordinates from hidden inputs
    const initialXStr = await xInput.inputValue();
    const initialYStr = await yInput.inputValue();
    // Get canvas dimensions for coordinate calculation
    const canvasBox = await canvas.boundingBox();
    if (!canvasBox) throw new Error('Canvas not found');

    // Define drag distance
    const dx = 50;
    const dy = 25;

    // Drag the element to a new position
    await drag(page, element, { dx, dy });

    // Get the new coordinate values from the hidden inputs
    const newXStr = await xInput.inputValue();
    const newYStr = await yInput.inputValue();

    // Calculate expected percentage values based on drag distance and canvas size
    const expectedX = parseFloat(initialXStr) + (dx / canvasBox.width) * 100;
    const expectedY = parseFloat(initialYStr) + (dy / canvasBox.height) * 100;
    // 1. Verify the hidden input values were updated correctly
    expect(parseFloat(newXStr)).toBeCloseTo(expectedX, 1);
    expect(parseFloat(newYStr)).toBeCloseTo(expectedY, 1);

    // Save the theme
    await page.locator('input[type="submit"]').click();
    await expect(page.getByText('Theme was successfully updated')).toBeVisible();
    // Navigate to dashboard to generate a new paper with the updated theme
    await page.goto('/papers/new');
    await page.getByText('Marvel').filter({ visible: true }).first().click({ force: true }); // uncheck Marvel
    await page.locator('#file-upload').setInputFiles('spec/fixtures/files/satoshi.jpg');
    await turboCableConnected(page);
    await expect(page.getByText('Processing...')).toBeHidden();
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.getByText('Processing...')).toBeVisible();
    await expect(page.getByText('Processing...')).toBeHidden();

    await app('perform_jobs');
    // Open the print preview for the newly generated paper
    // const printPromise = page.waitForEvent('popup');
    await page.getByRole('link', {name: 'Finalize Paper'}).click()
    await page.waitForURL(/\/papers\/\d+$/);

    // await page.locator('#preview-column .papers-item-component').first().click();
    // const print = await printPromise;

    // Verify the element in the print preview has the new coordinates
    const canvaItem = page.locator('.canva-item[data-canva-item-name-value="publicAddressQrcode"]');
    await expect(canvaItem).toHaveAttribute('data-canva-item-x-value', newXStr);
    await expect(canvaItem).toHaveAttribute('data-canva-item-y-value', newYStr);
  });

  test.afterEach(async ({ page }) => {
  });


  test('user can submit a theme', async ({ page }) => {
    await page.goto('/themes/new');

    // Verify the Tally form iframe is loaded
    const iframe = page.frameLocator('iframe[title="Bitcoin Designer"]');
    await expect(iframe.locator('body')).toContainText('Upload the front of your Bitcoin note');
  });
});