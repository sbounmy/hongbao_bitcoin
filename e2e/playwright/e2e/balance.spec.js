const { test, expect } = require('../support/test-setup');
const { appVcrInsertCassette, forceLogin , appVcrEjectCassette } = require('../support/on-rails');

async function fillMnemonic(page, mnemonic) {
    const words = mnemonic.split(' '); // cant use forEach because of the async await
    for (let index = 0; index < words.length; index++) {
        const word = words[index];
        const fieldset = page.locator(`#hong_bao_mnemonic_${index}`);
        expect(fieldset).toBeVisible();
        const input = fieldset.locator('input');
        await input.click();
        await input.pressSequentially(word)
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
    await appVcrInsertCassette('balance', { allow_playback_repeats: true })
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn?testnet=true');
    await expect(page.locator('body')).toContainText('₿0.00018709', { timeout: 10_000 });
    await expect(page).toHaveURL(/step=1/);
    await expect(page.getByRole('button', { name: "Next →" })).toBeEnabled();
    await page.getByRole('button', { name: "Next →" }).click();
    await expect(page.getByRole('button', { name: "24 Words" })).toBeVisible();
    await page.getByRole('button', { name: "24 Words" }).click();
    await page.waitForTimeout(1_000); // wait for js to fully load
    await fillMnemonic(page, "tilt cinnamon stick voice other pulse print rain broken man frost library chunk element leader side acquire copy code east abandon then dose smooth");
    await expect(page.getByRole('button', { name: "Continue" })).toBeEnabled();
    await page.getByRole('button', { name: "Continue" }).click();
    await expect(page.getByText('Enter Destination')).toBeVisible();
  });

  test('user cant check transfer with invalid mnemonic checksum', async ({ page }) => {
    await appVcrInsertCassette('balance', { allow_playback_repeats: true })
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn?testnet=true');
    await expect(page.locator('body')).toContainText('₿0.00018709', { timeout: 10_000 });
    await expect(page).toHaveURL(/step=1/);
    await expect(page.getByRole('button', { name: "Next →" })).toBeEnabled();
    await page.getByRole('button', { name: "Next →" }).click();
    await expect(page.getByRole('button', { name: "24 Words" })).toBeVisible();
    await page.getByRole('button', { name: " 24 Words" }).click();
    await page.waitForTimeout(1_000); // wait for js to fully load
    await fillMnemonic(page, "tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt tilt");
    await expect(page.getByRole('button', { name: "Continue" })).toBeDisabled();
    await expect(page.getByText('Invalid mnemonic checksum. Please check your words.')).toBeVisible();
  });

  test('user cant check transfer with invalid mnemonic for given address', async ({ page }) => {
    await appVcrInsertCassette('balance', { allow_playback_repeats: true })
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn?testnet=true');
    await expect(page.locator('body')).toContainText('₿0.00018709', { timeout: 10_000 });
    await expect(page).toHaveURL(/step=1/);
    await expect(page.getByRole('button', { name: "Next →" })).toBeEnabled();
    await page.getByRole('button', { name: "Next →" }).click();
    await expect(page.getByRole('button', { name: "24 Words" })).toBeVisible();
    await page.getByRole('button', { name: " 24 Words" }).click();
    await page.waitForTimeout(1_000); // wait for js to fully load
    await fillMnemonic(page, "gesture slide require response thumb shy option use bundle outer cream nest source pulp reduce endless bind toss collect pole fault crouch rib tiger");
    await expect(page.getByRole('button', { name: "Continue" })).toBeDisabled();
    await expect(page.getByText('This mnemonic does not correspond to the address tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn')).toBeVisible();
    // cPYpAjGY3GK1jTfGSVBoe6kS1hvRAY87vDbj2ZSbpgJA2inGHwfY
    await appVcrEjectCassette();
    await appVcrInsertCassette('balance_0', { allow_playback_repeats: true })
    await page.goto('/hong_baos/tb1qxzc08ky2zh9mhqvss2u4smwlgrs5a36wdugr4p?testnet=true');
    await expect(page.locator('body')).toContainText('₿0', { timeout: 10_000 });
    await expect(page.getByRole('button', { name: "Next →" })).toBeDisabled();
  });

});