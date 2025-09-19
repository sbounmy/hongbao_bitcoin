import { test, expect } from '../../support/test-setup';
import { forceLogin } from '../../support/on-rails';

test.describe('Admin Quotes Management', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/quotes'
    });
  });

  test('displays quotes list with all columns', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Quotes' })).toBeVisible();

    // Check column headers are visible using more specific selectors
    await expect(page.locator('th').filter({ hasText: 'Author' }).first()).toBeVisible();
    await expect(page.locator('th').filter({ hasText: 'Quote' })).toBeVisible();
    await expect(page.locator('th').filter({ hasText: 'Products' })).toBeVisible();
    await expect(page.locator('th').filter({ hasText: 'Published At' })).toBeVisible();

    // Check for actual quote data
    await expect(page.getByText('Andreas Antonopoulos')).toBeVisible();
    await expect(page.getByText('Future Author')).toBeVisible();
  });

  test('creates a new quote', async ({ page }) => {
    await page.getByRole('link', { name: 'New Quote' }).click();

    await expect(page.getByRole('heading', { name: 'New Quote' })).toBeVisible();

    await page.getByLabel('Position').fill('1');

    await page.getByLabel('Author').fill('Test Author');
    await page.getByLabel('Text').fill('This is a test quote about Bitcoin');
    await page.getByLabel('Published at').fill('2025-02-18T11:08:58');

    await page.getByRole('button', { name: 'Create Quote' }).click();

    await expect(page.getByText('Quote was successfully created.')).toBeVisible();

    await expect(page.getByText('Test Author').first()).toBeVisible();
    await expect(page.getByText('This is a test quote about Bitcoin').first()).toBeVisible();
  });

  test('edits an existing quote', async ({ page }) => {
    await page.getByRole('link', { name: 'Edit', exact: true }).first().click();

    await expect(page.getByRole('heading', { name: 'Edit Quote' })).toBeVisible();

    await page.getByLabel('Author').fill('Updated Author');
    await page.getByLabel('Text').fill('This is an updated quote about Bitcoin');


    await page.getByRole('button', { name: 'Update Quote' }).click();

    await expect(page.getByText('Quote was successfully updated.')).toBeVisible();
    await page.goto('/bitcoin-quotes/updated-author-this-is-an-updated-quote-about-bitcoin');
    await expect(page.getByText('Updated Author').first()).toBeVisible();
    await expect(page.getByText('This is an updated quote about Bitcoin')).toBeVisible();
});

  test('uploads avatar image for quote', async ({ page }) => {
    await page.getByRole('link', { name: 'Edit', exact: true }).first().click();

    await page.locator('#content_quote_avatar').setInputFiles('spec/fixtures/files/satoshi.jpg')

    await page.getByRole('button', { name: 'Update Quote' }).click();
    await expect(page.getByText('Quote was successfully updated.')).toBeVisible();
  });

  test('views quote details and related products', async ({ page }) => {
    await page.getByRole('link', { name: 'View', exact: true }).first().click();

    await expect(page.getByRole('heading', { name: /^Quote #\d+/ })).toBeVisible();

    await expect(page.getByText('Author')).toBeVisible();
    await expect(page.getByText('Text')).toBeVisible();

    const relatedProductsPanel = page.locator('h3:has-text("Related Products")').first();
    await expect(relatedProductsPanel).toBeVisible();

    await expect(page.getByRole('link', { name: 'Add Product' })).toBeVisible();
  });


  test('deletes a quote', async ({ page }) => {
    await page.getByRole('link', { name: 'View', exact: true }).last().click();

    page.on('dialog', dialog => dialog.accept());
    await page.getByRole('link', { name: 'Delete Quote' }).click();

    await expect(page.getByText('Quote was successfully destroyed.')).toBeVisible();
  });
});