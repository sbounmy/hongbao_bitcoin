const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin , app } = require('../support/on-rails');

async function fillMnemonic(page, mnemonic) {
    const words = mnemonic.split(' '); // cant use forEach because of the async await
    for (let index = 0; index < words.length; index++) {
        const word = words[index];
        const fieldset = page.locator(`#hong_bao_mnemonic_${index}`);
        const input = fieldset.locator('input');
        await input.click();
        await input.fill(word)
        await expect(input).toHaveValue(word);
        await expect(fieldset.locator('.validation-icon[data-word-target="validIcon"]')).toBeVisible();
    }
}

test.describe('Balance', () => {

  test('user can scan a qrcode', async ({ page }) => {
    await page.goto('/hong_baos');
    await expect(page.locator('body')).toContainText('QR Code');
  });

  test('user can check balance and transfer tokens', async ({ page }) => {
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn?testnet=true');
    await expect(page.locator('body')).toContainText('₿0.00018709', { timeout: 10_000 });
    await expect(page).toHaveURL(/step=1/);
    await expect(page.getByRole('button', { name: "Next →" })).toBeEnabled();
    await page.getByRole('button', { name: "Next →" }).click();
    await expect(page.getByText('24 Words')).toBeVisible();
    await page.getByRole('button', { name: /24 Words/ }).click();
    await fillMnemonic(page, "tilt cinnamon stick voice other pulse print rain broken man frost library chunk element leader side acquire copy code east abandon then dose smooth");

    await page.getByRole('button', { name: /Transfer/ }).click();
    await expect(page.locator('body')).toContainText('Transfer');
  });
});