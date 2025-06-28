import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, savePageAs } from '../support/on-rails';

const expectGeneratedKeys = async (page) => {
  await expect(page.locator('#public_address_text')).toHaveValue(/^bc1/)
  await expect(page.locator('#private_key_text')).toHaveValue(/^L|K/)
  const mnemonic = await page.locator('#mnemonic_text').inputValue()
  const mnemonicWords = mnemonic.split(' ')
  expect(mnemonicWords).toHaveLength(24)
}

test.describe('PDF Generation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/papers/1');
  });

  test('should generate PDF with correct layout and content', async ({ page }) => {
    // Wait for PDF preview to be visible
    const pdf = page.locator('[data-pdf-target="content"]')
    await expect(pdf).toBeVisible();

    // Check main sections
    await expect(pdf.getByText('SLIP INSIDE THE HONG₿AO ENVELOPE')).toBeVisible();
    await expect(pdf.getByText('ABOUT BITCOIN')).toBeVisible();
    await expect(pdf.getByText('HOW IT WORKS')).toBeVisible();
  });

  test('should handle PDF download', async ({ page, context }) => {
    await expectGeneratedKeys(page)

    // Start waiting for download before clicking
    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Next' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();
    await expect(page.getByText('Choose your preferred way to send bitcoin to this address')).toBeVisible();
  });

  test('user can input custom keys', async ({ page }) => {
    await expectGeneratedKeys(page)

    await expect(page.getByRole('alert', { name: 'Use custom keys at your own risk.' })).toBeHidden()
    // fill public address
    await page.locator('#public_address_text').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Accept' }).click()
    await page.locator('#public_address_text').fill('my-own-public-addres')
    await page.locator('#public_address_text').pressSequentially('s')
    await expect(page.locator('body')).toContainText("You're using custom keys.")
    await expect(page.locator('#public_address_text')).toHaveValue('my-own-public-address')
    await expect(page.locator('#private_key_text')).toHaveValue('')
    await expect(page.locator('#mnemonic_text')).toHaveValue('')

    // fill private key
    await page.locator('#private_key_text').fill('my-own-private-key')
    await expect(page.locator('#private_key_text')).toHaveValue('my-own-private-key')
    await expect(page.locator('#mnemonic_text')).toHaveValue('')

    // fill recovery phrase
    await page.locator('#mnemonic_text').fill('my own mnemonic is here but you can change it')
    await expect(page.locator('#mnemonic_text')).toHaveValue('my own mnemonic is here but you can change it')

    // check if pdf is generated with correct values
    await expect(page.locator('[data-canva-item-name-value="publicAddressText"]')).toHaveAttribute('data-canva-item-text-value', 'my-own-public-address')
    await expect(page.locator('[data-canva-item-name-value="privateKeyText"]')).toHaveAttribute('data-canva-item-text-value', 'my-own-private-key')
    await expect(page.locator('[data-canva-item-name-value="mnemonicText"]')).toHaveAttribute('data-canva-item-text-value', 'my own mnemonic is here but you can change it')

    // generate new keys
    await page.locator('#bitcoin-generate').click()
    await expectGeneratedKeys(page)

    // re-ask for confirmation
    await page.locator('#public_address_text').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Cancel' }).click()
  });

  test('user top up notice for custom keys', async ({ page }) => {
    await expectGeneratedKeys(page)

    // fill public address
    await page.locator('#public_address_text').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Accept' }).click()
    await page.locator('#public_address_text').fill('my-own-public-addres')
    await page.locator('#public_address_text').pressSequentially('s')
    await expect(page.locator('body')).toContainText("You're using custom keys.")

    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Next' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();

    await expect(page.getByText('Card / Bank Transfer top up might not be available for custom keys.')).toBeVisible();
  });

  test('user top up no notice for generated keys', async ({ page }) => {
    await expectGeneratedKeys(page)

    const downloadPromise = page.waitForEvent('download');

    // Click download button (adjust selector as needed)
    await page.getByRole('button', { name: 'Download PDF' }).click();

    // Wait for download to start
    const download = await downloadPromise;

    // Verify download started
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);

    const nextButton = page.getByRole('button', { name: 'Next' });
    await expect(nextButton).toBeEnabled();
    await nextButton.click();

    await expect(page.getByText('Card / Bank Transfer top up might not be available for custom keys.')).toBeHidden();
  });

  test('user can go offline with save page as and interact with it', async ({ page, context }) => {
    await savePageAs(page, context, async (offlinePage) => {
      await expect(offlinePage.locator('body')).toContainText(/SLIP INSIDE THE HONG.*AO ENVELOPE/);
      var addresses = [];
      for (let i = 0; i < 10; i++) {
        addresses.push(await offlinePage.locator('#public_address_text').inputValue());
        await offlinePage.locator("#bitcoin-generate").click();
      }

      const uniq = [...new Set(addresses)];
      // check all addresses are different
      expect(uniq).toHaveLength(10);

      const downloadPromise = offlinePage.waitForEvent('download');

      // Click download button (adjust selector as needed)
      await offlinePage.getByRole('button', { name: 'Download PDF' }).click();

      // Wait for download to start
      const download = await downloadPromise;

      // Verify download started
      expect(download.suggestedFilename()).toMatch(/\.pdf$/);
      const nextButton = offlinePage.getByRole('button', { name: 'Next' });
      await expect(nextButton).toBeEnabled();
      await nextButton.click();

      // top up page
      await expect(offlinePage.getByText('Choose your preferred way to send bitcoin to this address')).toBeVisible();
    });
  });
});