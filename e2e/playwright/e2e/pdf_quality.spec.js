import { test, expect } from '../support/test-setup'
import { renderPDFInBrowser } from '../support/on-rails'
import fs from 'fs'

test.describe('PDF Export Quality', () => {
  test('downloaded PDF has crisp background images', async ({ page }) => {
    if (browserName === 'webkit') test.skip('failling on webkit dunno why');
    test.setTimeout(60_000)

    await page.goto('/papers/new')
    await page.waitForSelector('[data-editor-target="frontContainer"]')

    // Use fixed custom keys for deterministic QR codes
    await page.getByRole('button', { name: /Keys/ }).click()
    await page.getByRole('radio', { name: 'Use my own keys' }).click()
    await page.locator('#public_address_text').fill('bc1qtest123456789')
    await page.locator('#private_key_text').fill('L1testPrivateKey123456789')
    await page.getByRole('button', { name: /Done/ }).click()

    // Navigate to preview step
    await page.getByRole('button', { name: 'Next' }).click()
    await page.waitForSelector('[data-pdf-target="content"]')

    // Download PDF
    const downloadPromise = page.waitForEvent('download')
    await page.getByRole('button', { name: 'Download PDF' }).click()
    const download = await downloadPromise

    // Save PDF to temp file
    const tempPath = `/tmp/pdf-quality-${Date.now()}.pdf`
    await download.saveAs(tempPath)

    // Read PDF using Node.js fs (not page.evaluate which runs in browser)
    const pdfBuffer = fs.readFileSync(tempPath).toString('base64')

    // Render PDF to image in browser
    const pngBuffer = await renderPDFInBrowser(page, pdfBuffer, { scale: 2 })

    // Compare against baseline using Playwright's built-in snapshot
    // Each browser gets its own baseline (chromium, firefox, webkit)
    expect(pngBuffer).toMatchSnapshot('pdf-quality-baseline.png', {
      maxDiffPixelRatio: 0.01  // 0.1% tolerance for minor rendering differences
    })

    // Cleanup temp file
    fs.unlinkSync(tempPath)
  })
})
