import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, savePageAs, authenticatePDF, fs } from '../support/on-rails';
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';

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
    await page.goto('/papers/1');
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

    await page.locator('#public_address_text').pressSequentially('my-own-public-address')
    await page.locator('#private_key_text').fill('my-own-private-key')
    await page.locator('#mnemonic_text').fill('my own mnemonic is here but you can change it')

    // check if pdf is generated with correct values
    await expect(page.locator('[data-canva-item-name-value="publicAddressText"]').first()).toHaveAttribute('data-canva-item-text-value', 'my-own-public-address')
    await expect(page.locator('[data-canva-item-name-value="privateKeyText"]').first()).toHaveAttribute('data-canva-item-text-value', 'my-own-private-key')
    await expect(page.locator('[data-canva-item-name-value="mnemonicText"]').first()).toHaveAttribute('data-canva-item-text-value', 'my own mnemonic is here but you can change it')
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

  test.describe('PDF Password Protection', () => {
    test.beforeEach(async ({ page }) => {
      // The parent beforeEach already navigates to /papers/1
      // await page.getByRole('button', { name: 'Generate new keys' }).click();
      // await expectGeneratedKeys(page);
      await page.getByRole('button', { name: /Next/ }).click();
      await page.getByRole('button', { name: /Password/ }).click()
    });

    test('password can be weak, fair, strong or very strong', async ({ page }) => {
      test.setTimeout(60_000);
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const meterText = page.locator('[data-password-meter-target="meterText"]');
      const meterFill = page.locator('[data-password-meter-target="meterFill"]');

      // Test various password strengths - all should allow download
      const passwords = [
        { password: 'aaaaaa', expectedStrength: 'Weak' },           // Weak: repeated chars, too short
        { password: 'alllowercase123!', expectedStrength: 'Fair' }, // No uppercase letters
        { password: 'NoNumbers!Pass', expectedStrength: 'Fair' },   // No numbers
        { password: 'NoSpecial123Pass', expectedStrength: 'Very Strong' }, // No special characters
        { password: 'Strong123!Pass', expectedStrength: 'Very Strong' }, // Strong password
        { password: 'VeryStrong123!@#Pass', expectedStrength: 'Very Strong' } // Very strong password
      ];

      for (const { password, expectedStrength } of passwords) {
        await passwordInput.fill(password);

        // Wait a bit for validation to trigger
        await page.waitForTimeout(200);

        // Verify password meter shows appropriate strength
        await expect(meterText).toHaveText(expectedStrength);

        // Verify meter fill is visible
        await expect(meterFill).toBeVisible();

        // Verify download button is ENABLED even for weak passwords
        // Password meter is advisory only - users can download with any strength
        await expect(downloadButton).toBeEnabled();

        // Clear for next test
        await passwordInput.clear();
      }
    });

    test('can setup strong password', async ({ page }) => {
      test.setTimeout(60_000);
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const meterText = page.locator('[data-password-meter-target="meterText"]');
      const meterFill = page.locator('[data-password-meter-target="meterFill"]');

      // Test a strong password that meets all requirements
      const strongPassword = 'StrongP@ss123!';

      await passwordInput.fill(strongPassword);

      // Wait for validation to complete
      await page.waitForTimeout(200);

      // Verify password meter shows strong or very strong
      const strengthText = await meterText.textContent();
      expect(['Strong', 'Very Strong']).toContain(strengthText);

      // Verify meter fill has appropriate width (should be > 50%)
      const fillWidth = await meterFill.evaluate(el => el.style.width);
      expect(parseInt(fillWidth)).toBeGreaterThan(50);

      await page.locator('.modal-backdrop:visible').click()

      // Verify download button is enabled
      await expect(downloadButton).toBeEnabled();

      // Test download works with password
      const downloadPromise = page.waitForEvent('download');
      await downloadButton.click();
      const download = await downloadPromise;

      // Verify download started
      expect(download.suggestedFilename()).toMatch(/\.pdf$/);

      // Verify Next button is enabled after download
      const nextButton = page.getByRole('button', { name: 'Fund wallet' });
      await expect(nextButton).toBeEnabled();
      await nextButton.click();
      await expect(page.getByText('Buy BTC')).toBeVisible();

    });

    test('empty password field allows unencrypted download', async ({ page }) => {
      test.setTimeout(60_000);
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const meterText = page.locator('[data-password-meter-target="meterText"]');

      // First type something then clear to ensure validation runs
      await passwordInput.fill('SomeText');
      await passwordInput.clear();

      // Wait for validation
      await page.waitForTimeout(200);

      // Meter should show "Too Short" or similar for empty password
      await expect(meterText).toHaveText('Weak');
      await page.locator('.modal-backdrop:visible').click()

      // Test download works without password
      const downloadPromise = page.waitForEvent('download');
      await downloadButton.click();
      const download = await downloadPromise;

      // Verify download started
      expect(download.suggestedFilename()).toMatch(/\.pdf$/);
    });

    test('downloaded PDF is encrypted with the correct password', async ({ page }) => {
      test.setTimeout(60_000);
      // This test verifies that the PDF has AES-256 encryption (PDF 1.7ext3)
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const testPassword = 'TestP@ssw0rd123';

      // Set a strong password
      await passwordInput.fill(testPassword);
      await page.waitForTimeout(200);
      await expect(downloadButton).toBeEnabled();

      await page.locator('.modal-backdrop:visible').click()
      // Download the PDF
      const downloadPromise = page.waitForEvent('download');
      await downloadButton.click();
      const download = await downloadPromise;

      // Save the PDF to a temporary location
      const tempPath = './test-download-' + Date.now() + '.pdf';
      await download.saveAs(tempPath);

      try {
        // Read the PDF file
        const dataBuffer = fs.readFileSync(tempPath);
        const pdfContent = dataBuffer.toString('latin1');

        // Check for PDF 1.7ext3 (AES-256 encryption)
        const isPDF17ext3 = pdfContent.includes('%PDF-1.7');
        const hasV5Encryption = pdfContent.includes('/V 5') || pdfContent.includes('/V5');
        const hasAESV3 = pdfContent.includes('/AESV3');

        // Verify PDF is encrypted with AES-256
        expect(isPDF17ext3).toBe(true);
        expect(hasV5Encryption || hasAESV3).toBe(true);

        // Try to open without password using pdfjs-dist - should fail
        const uint8Array = new Uint8Array(dataBuffer);
        let openedWithoutPassword = false;
        try {
          await getDocument({ data: uint8Array }).promise;
          openedWithoutPassword = true;
        } catch (error) {
          // Expected to fail - PDF is encrypted
        }
        expect(openedWithoutPassword).toBe(false);
      } finally {
        // Clean up the temporary file
        fs.unlinkSync(tempPath);
      }
    });

    test('can decrypt and read PDF with correct password', async ({ page }) => {
      // This test verifies that we can actually decrypt and read the PDF content with the password
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const testPassword = 'TestP@ssw0rd123';

      // Set a strong password
      await passwordInput.fill(testPassword);
      await page.waitForTimeout(100);
      await expect(downloadButton).toBeEnabled();

      await page.locator('.modal-backdrop:visible').click()
      // Download the PDF
      const downloadPromise = page.waitForEvent('download');
      await downloadButton.click();
      const download = await downloadPromise;

      // Save the PDF to a temporary location
      const tempPath = './test-download-' + Date.now() + '.pdf';
      await download.saveAs(tempPath);

      try {
        // Use the authenticatePDF helper
        const result = await authenticatePDF(tempPath, testPassword);

        // Verify authentication succeeded
        expect(result.success).toBe(true);

        // The PDF contains an image (from html2canvas), not text
        // So we can't extract text content, but we can verify:
        // 1. The PDF was successfully decrypted
        // 2. It has the correct number of pages
        expect(result.numPages).toBe(1);

      } finally {
        // Clean up the temporary file
        fs.unlinkSync(tempPath);
      }
    });

    test('cannot read PDF with wrong password', async ({ page }) => {
      // This test verifies that the PDF cannot be read with an incorrect password
      const passwordInput = page.getByPlaceholder(/Enter password/);
      const downloadButton = page.getByRole('button', { name: 'Download PDF' });
      const correctPassword = 'TestP@ssw0rd123';
      const wrongPassword = 'WrongPassword123!';

      // Set a strong password
      await passwordInput.fill(correctPassword);
      await page.waitForTimeout(100);
      await page.locator('.modal-backdrop:visible').click()

      await expect(downloadButton).toBeEnabled();

      // Download the PDF
      const downloadPromise = page.waitForEvent('download');
      await downloadButton.click();
      const download = await downloadPromise;

      // Save the PDF to a temporary location
      const tempPath = './test-download-' + Date.now() + '.pdf';
      await download.saveAs(tempPath);

      try {
        // Try to read the PDF with the wrong password using the helper
        const result = await authenticatePDF(tempPath, wrongPassword);

        // Verify authentication failed
        expect(result.success).toBe(false);
        expect(result.content).toBeNull();
        expect(result.error).toContain('Incorrect Password');
      } finally {
        // Clean up the temporary file
        fs.unlinkSync(tempPath);
      }
    });
  });
});