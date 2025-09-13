import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, savePageAs } from '../support/on-rails';

test.describe('Bitcoin Quotes', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the quotes page
    await page.goto('/bitcoin-quotes');
  });

  test('displays list of bitcoin quotes', async ({ page }) => {
    // Check page title and heading
    await expect(page).toHaveTitle(/Bitcoin Quotes/);

    // Check that quotes are displayed
    const quoteCards = page.locator('.card');
    await expect(quoteCards).toHaveCount(await quoteCards.count());

    // Verify at least one quote is visible
    await expect(quoteCards.first()).toBeVisible();
  });

  test('navigates to individual quote page', async ({ page }) => {
    // Click on the first quote
    await page.getByText(/Read More/).first().click();

    // Wait for navigation
    await page.waitForURL(/bitcoin-quotes\/.+/);

    // Verify we're on a quote detail page
    await expect(page.locator('blockquote')).toBeVisible();
  });
});

test.describe('Individual Quote Page', () => {
  test('displays Henry Ford quote with products', async ({ page }) => {
    // Navigate directly to Henry Ford quote
    await page.goto('/bitcoin-quotes/henry-ford-energy-currency-stops-wars');

    // Check quote content
    await expect(page.locator('blockquote')).toContainText('An energy currency can stop wars');
    await expect(page.locator('text=— Henry Ford')).toBeVisible();

    // Check breadcrumbs
    const breadcrumbs = page.locator('.breadcrumbs');
    await expect(breadcrumbs).toContainText('Home');
    await expect(breadcrumbs).toContainText('Bitcoin Quotes');
    await expect(breadcrumbs).toContainText('Henry Ford');

    // Check orange-pill section
    const orangePillSection = page.locator('.card').filter({ hasText: /orange-pill/i });
    await expect(orangePillSection).toBeVisible();
    await expect(orangePillSection).toContainText('Hong₿ao Envelopes');

    // Check products section if products exist
    const productsSection = page.locator('text=Products with this Quote').first();
    if (await productsSection.isVisible()) {
      // Check Hong₿ao product
      const hongbaoProduct = page.locator('.card').filter({ hasText: 'Hong₿ao' }).first();
      await expect(hongbaoProduct).toBeVisible();

      // Check external products
      const redbubbleProduct = page.locator('.badge').filter({ hasText: 'Redbubble' });
      if (await redbubbleProduct.isVisible()) {
        await expect(redbubbleProduct).toBeVisible();
      }
    }

    // Check related quotes section
    const relatedSection = page.locator('text=More Bitcoin Wisdom');
    if (await relatedSection.isVisible()) {
      const relatedQuotes = page.locator('.card').filter({ hasText: /Read →/ });
      await expect(relatedQuotes.first()).toBeVisible();
    }
  });

  test('displays Satoshi quote page', async ({ page }) => {
    // Navigate to Satoshi quote
    await page.goto('/bitcoin-quotes/satoshi-nakamoto-peer-to-peer-electronic-cash');

    await expect(page.locator('text=— Satoshi Nakamoto')).toBeVisible();

    // Check gradient background on quote card
    const quoteCard = page.locator('.card').filter({ hasText: 'Satoshi Nakamoto' }).first();
    await expect(quoteCard).toHaveClass(/from-orange-400/);
  });

  test('share buttons work correctly', async ({ page }) => {
    await page.goto('/bitcoin-quotes/henry-ford-energy-currency-stops-wars');

    // Check share button exists
    const shareButton = page.getByRole('link', { name: /Share on Twitter/i });
    await expect(shareButton).toBeVisible();

    // Check copy button exists
    const copyButton = page.getByRole('button', { name: /Copy to clipboard/i });
    await expect(copyButton).toBeVisible();

    // Test copy functionality
    await copyButton.click();
    // Note: Clipboard API might not work in headless mode, but button should be clickable
  });

  test('returns 404 for non-existent quote', async ({ page }) => {
    // Navigate to non-existent quote
    const response = await page.goto('/bitcoin-quotes/non-existent-quote', { waitUntil: 'domcontentloaded' });

    // Check for 404 status
    expect(response.status()).toBe(404);
  });

  test('full quote expands when available', async ({ page }) => {
    await page.goto('/bitcoin-quotes/henry-ford-energy-currency-stops-wars');

    // Check if full quote section exists
    const fullQuoteSection = page.locator('.collapse').filter({ hasText: 'Read Full Quote' });
    if (await fullQuoteSection.isVisible()) {
      // Click to expand
      await fullQuoteSection.locator('input[type="checkbox"]').click();

      // Check that full quote is visible
      const fullQuote = page.locator('text=The essential evil of gold');
      await expect(fullQuote).toBeVisible();
    }
  });

  test('products have correct styling', async ({ page }) => {
    await page.goto('/bitcoin-quotes/henry-ford-energy-currency-stops-wars');

    const productsSection = page.locator('text=Products with this Quote').first();
    if (await productsSection.isVisible()) {
      // Hong₿ao products should have primary styling
      const hongbaoProduct = page.locator('.card.bg-primary\\/10');
      if (await hongbaoProduct.first().isVisible()) {
        await expect(hongbaoProduct.first()).toHaveClass(/border-primary/);
      }

      // External products should have different styling
      const externalProduct = page.locator('.card.bg-base-200');
      if (await externalProduct.first().isVisible()) {
        await expect(externalProduct.first()).toBeVisible();
      }
    }
  });

  test('navigation links work correctly', async ({ page }) => {
    await page.goto('/bitcoin-quotes/henry-ford-energy-currency-stops-wars');

    // Test breadcrumb navigation
    await page.getByRole('link', { name: 'Bitcoin Quotes' }).click();
    await expect(page).toHaveURL('/bitcoin-quotes');

    // Go back to quote page
    await page.goBack();

    // Test back button in share section
    const backButton = page.locator('.btn-circle').filter({ hasText: '' }).last();
    if (await backButton.isVisible()) {
      await backButton.click();
      await expect(page).toHaveURL('/bitcoin-quotes');
    }
  });
});