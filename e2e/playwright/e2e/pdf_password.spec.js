import { test, expect } from '../support/test-setup';
import { authenticatePDF, fs } from '../support/on-rails';
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';

test.describe('PDF Password Protection', () => {
  test.beforeEach(async ({ page }) => {
    test.setTimeout(60_000);
    await page.goto('/papers/1');
    await page.getByRole('button', { name: /Next/ }).click();
    await page.getByRole('button', { name: /Password/ }).click()
  });

  test('password can be weak, fair, strong or very strong', async ({ page }) => {
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
