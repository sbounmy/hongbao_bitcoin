import { test, expect } from '../../support/test-setup';
import { forceLogin } from '../../support/on-rails';

test.describe('Admin Products Management', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/products'
    });
  });

  test('creates a new product', async ({ page }) => {
    await page.getByRole('link', { name: 'New Product' }).click();
    await expect(page.getByRole('heading', { name: 'New Product' })).toBeVisible();

    // Select parent quote
    await page.getByLabel('Parent Quote').selectOption('Andreas Antonopoulos - Not your keys, not your coins' );

    // Fill basic fields
    await page.getByLabel('Slug').fill('test-product');
    await page.getByLabel('Position').fill('1');

    await page.getByLabel('Title').fill('Test Bitcoin Envelope');
    await page.getByLabel('Shop').fill('Hong₿ao');
    await page.getByLabel('Price').fill('10');
    await page.getByLabel('Currency').fill('USD');
    await page.getByLabel('URL').fill('https://www.hongbao.com/test-bitcoin-envelope');
    await page.getByLabel('Published at').fill('2025-02-18T11:08:58');

    await page.getByRole('button', { name: 'Create Product' }).click();
    await expect(page.getByText('Product was successfully created.')).toBeVisible();

    await page.goto('/bitcoin-quotes/andreas-antonopoulos-not-your-keys');
    await expect(page.getByText('Test Bitcoin Envelope')).toBeVisible();
  });

  test('edits an existing product', async ({ page }) => {
    await page.goto('/admin/products/hongbao-andreas-antonopoulos-envelope-set/edit');

    await page.getByLabel('Title').fill('Updated Test Bitcoin Envelope');
    await page.getByLabel('Price').fill('30');
    await page.getByLabel('Currency').fill('USD');
    await page.getByLabel('URL').fill('https://www.hongbao.com/test-bitcoin-envelope');
    await page.getByLabel('Published at').fill('2025-02-18T11:08:58');

    await page.getByRole('button', { name: 'Update Product' }).click();
    await expect(page.getByText('Product was successfully updated.')).toBeVisible();
    await page.goto('/bitcoin-quotes/andreas-antonopoulos-not-your-keys');
    await expect(page.getByText('Updated Test Bitcoin Envelope')).toBeVisible();
  });

  test('uploads product image', async ({ page }) => {
    await page.goto('/admin/products/hongbao-andreas-antonopoulos-envelope-set/edit');

    await page.locator('#content_product_image').setInputFiles('spec/fixtures/files/satoshi.jpg');

    await page.getByRole('button', { name: 'Update Product' }).click();
    await expect(page.getByText('Product was successfully updated.')).toBeVisible();
  });


  test('deletes a product', async ({ page }) => {
    await page.goto('/admin/products/hongbao-andreas-antonopoulos-envelope-set');
    page.on('dialog', dialog => dialog.accept());
    await page.getByRole('link', { name: 'Delete Product' }).click();

    await expect(page.getByText('Product was successfully destroyed.')).toBeVisible();
    await expect(page.getByText('Andreas Antonopoulos')).not.toBeVisible();
  });
});