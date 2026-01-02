import { test, expect } from '../support/test-setup';
import { savePageAs } from '../support/on-rails';

const expectGeneratedKeys = async (page) => {
  await page.getByRole('button', {name: /Keys/}).click()

  await expect(page.locator('#public_address_text')).toHaveValue(/^bc1/)
  await expect(page.locator('#private_key_text')).toHaveValue(/^L|K/)
  const mnemonic = await page.locator('#mnemonic_text').inputValue()
  const mnemonicWords = mnemonic.split(' ')
  expect(mnemonicWords).toHaveLength(24)
  await page.getByRole('button', { name: /Done/}).click()
}

test.describe('PDF Generation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/papers/new');
  });

  test('should generate PDF with correct layout and content', async ({ page }) => {
    await page.getByRole('button', {name: /Next/}).click()
    // Wait for PDF preview to be visible
    const pdf = page.locator('[data-pdf-target="content"]')
    await expect(pdf).toBeVisible();

    // Check main sections
    await expect(pdf.getByText('SLIP INSIDE THE HONG₿AO ENVELOPE')).toBeVisible();
    await expect(pdf.getByText('ABOUT BITCOIN')).toBeVisible();
    await expect(pdf.getByText('HOW IT WORKS')).toBeVisible();
  });

  test('should handle PDF download', async ({ page, context }) => {
    test.setTimeout(60_000)

    await expectGeneratedKeys(page)

    await page.getByRole('button', { name: /Next/ }).click()
    // Start waiting for download before clicking
    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Fund wallet' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();
    await expect(page.getByText('Buy BTC')).toBeVisible();
  });

  test('user can input custom keys', async ({ page }) => {
    test.setTimeout(60_000)
    await page.getByRole('button', {name: /Keys/}).click()
    await page.getByRole('radio', { name: 'Use my own keys' }).click()

    await expect(page.locator('#public_address_text')).toBeEmpty()
    await expect(page.locator('#private_key_text')).toBeEmpty()
    await expect(page.locator('#mnemonic_text')).toBeEmpty()

    await page.locator('#public_address_text').fill('my-own-public-address')
    await page.locator('#private_key_text').fill('my-own-private-key')
    await page.locator('#mnemonic_text').fill('my own mnemonic is here but you can change it')

    // Verify elements are rendered in the DOM canvas with correct text
    await expect(page.locator('[data-element-type="public_address/text"]')).toContainText('my-own-public-address')
    await expect(page.locator('[data-element-type="private_key/text"]')).toContainText('my-own-private-key')
    await expect(page.locator('[data-element-type="mnemonic/text"]')).toContainText('my own mnemonic is here but you can change it')
  });

  test('user top up notice for custom keys', async ({ page }) => {
    test.setTimeout(60_000)
    await page.getByRole('button', {name: /Keys/}).click()
    await page.getByRole('radio', { name: 'Use my own keys' }).click()

    // fill public address
    await page.locator('#public_address_text').pressSequentially('my-own-public-address')
    await page.locator('#public_address_text').fill('my-own-public-addres')
    await page.locator('#private_key_text').fill('my-own-private-key')

    await page.locator('.modal-backdrop:visible').click()

    await page.getByRole('button', { name: 'Next' }).click()
    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    await expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Fund wallet' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();
    await expect(page.getByText('Buy BTC')).toBeVisible();

    await expect(page.getByText('Card / Bank Transfer top up might not be available for custom keys.')).toBeVisible();
  });

  test('user top up no notice for generated keys', async ({ page }) => {
    test.setTimeout(60_000)
    await expectGeneratedKeys(page)

    await page.getByRole('button', { name: 'Next' }).click()
    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    await expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Fund wallet' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();
    await expect(page.getByText('Buy BTC')).toBeVisible();

    await expect(page.getByText('Card / Bank Transfer top up might not be available for custom keys.')).toBeHidden();
  });

  test('user can go offline with save page as and interact with it', async ({ page, context, browserName }) => {
    if (browserName === 'webkit') test.skip('weird issue with webkit the downloaded event triggers but not catch but disabled_controller#remove');
    test.setTimeout(60_000);
    await savePageAs(page, context, async (offlinePage) => {
      await offlinePage.getByRole('button', {name: /Keys/}).click()
      await offlinePage.getByRole('radio', { name: 'Generate keys' }).click()
      await expect(offlinePage.locator('body')).toContainText(/SLIP INSIDE THE HONG.*AO ENVELOPE/);
      var addresses = [];
      for (let i = 0; i < 10; i++) {
        addresses.push(await offlinePage.locator('#public_address_text').inputValue());
        await offlinePage.locator("#bitcoin-generate").click();
      }

      const uniq = [...new Set(addresses)];
      // check all addresses are different
      expect(uniq).toHaveLength(10);

      await offlinePage.getByRole('button', { name: /Done/}).click()
      await offlinePage.getByRole('button', {name: /Next/}).click()
      const downloadPromise = offlinePage.waitForEvent('download');

      // Click download button (adjust selector as needed)
      await offlinePage.getByRole('button', { name: 'Download PDF' }).click();

      // Wait for download to start
      const download = await downloadPromise;

      // Verify download started
      await expect(download.suggestedFilename()).toMatch(/\.pdf$/);

      const nextButton = offlinePage.getByRole('button', { name: 'Fund wallet' });
      await expect(nextButton).toBeEnabled();
      await nextButton.click();
      await expect(offlinePage.getByText('Buy BTC')).toBeVisible();
    });
  });
});