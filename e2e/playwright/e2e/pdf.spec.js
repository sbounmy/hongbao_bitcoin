import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

const expectGeneratedKeys = async (page) => {
  await expect(page.getByLabel('Public Address')).toHaveValue(/^bc1/)
  await expect(page.getByLabel('Private Key')).toHaveValue(/^L|K/)
  const mnemonic = await page.getByLabel('Recovery Phrase (24 words)').inputValue()
  const mnemonicWords = mnemonic.split(' ')
  expect(mnemonicWords).toHaveLength(24)
}

test.describe('PDF Generation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/papers/1');
  });

  test('should generate PDF with correct layout and content', async ({ page }) => {
    // Wait for PDF preview to be visible
    await expect(page.locator('[data-pdf-target="content"]')).toBeVisible();

    // Check main sections
    await expect(page.getByText('SLIP INSIDE THE HONG₿AO ENVELOPE')).toBeVisible();
    await expect(page.getByText('ABOUT BITCOIN')).toBeVisible();
    await expect(page.getByText('HOW IT WORKS')).toBeVisible();
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
    await page.getByLabel('Public Address').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Accept' }).click()
    await page.getByLabel('Public Address').fill('my-own-public-addres')
    await page.getByLabel('Public Address').pressSequentially('s')
    await expect(page.getByRole('alert')).toContainText('Use custom keys at your own risk.')
    await expect(page.getByLabel('Public Address')).toHaveValue('my-own-public-address')
    await expect(page.getByLabel('Private Key')).toHaveValue('')
    await expect(page.getByLabel('Recovery Phrase (24 words)')).toHaveValue('')

    // fill private key
    await page.getByLabel('Private Key').fill('my-own-private-key')
    await expect(page.getByLabel('Private Key')).toHaveValue('my-own-private-key')
    await expect(page.getByLabel('Recovery Phrase (24 words)')).toHaveValue('')

    // fill recovery phrase
    await page.getByLabel('Recovery Phrase (24 words)').fill('my own mnemonic is here but you can change it')
    await expect(page.getByLabel('Recovery Phrase (24 words)')).toHaveValue('my own mnemonic is here but you can change it')

    // check if pdf is generated with correct values
    await expect(page.locator('[data-canva-item-name-value="publicAddressText"]')).toHaveAttribute('data-canva-item-text-value', 'my-own-public-address')
    await expect(page.locator('[data-canva-item-name-value="privateKeyText"]')).toHaveAttribute('data-canva-item-text-value', 'my-own-private-key')
    await expect(page.locator('[data-canva-item-name-value="mnemonicText"]')).toHaveAttribute('data-canva-item-text-value', 'my own mnemonic is here but you can change it')

    // generate new keys
    await page.locator('[data-action="bitcoin#generate dialog-key#reset"]').click()
    await expectGeneratedKeys(page)

    // re-ask for confirmation
    await page.getByLabel('Public Address').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Cancel' }).click()
  });

  test('user top up notice for custom keys', async ({ page }) => {
    await expectGeneratedKeys(page)

    // fill public address
    await page.getByLabel('Public Address').pressSequentially('my-own-public-address')
    await expect(page.getByText('Using your own key will clear the other keys.')).toBeVisible()
    await page.getByRole('button', { name: 'Accept' }).click()
    await page.getByLabel('Public Address').fill('my-own-public-addres')
    await page.getByLabel('Public Address').pressSequentially('s')
    await expect(page.getByRole('alert')).toContainText('Use custom keys at your own risk.')

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
});