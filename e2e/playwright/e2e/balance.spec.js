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

  test('user can check balance and transfer tokens with 24 words mnemonic', async ({ page }) => {
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
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn');
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
    await page.goto('/hong_baos/tb1qxzc08ky2zh9mhqvss2u4smwlgrs5a36wdugr4p');
    await expect(page.locator('body')).toContainText('₿0', { timeout: 10_000 });
    await expect(page.getByRole('button', { name: "Next →" })).toBeDisabled();
  });

  test('user can check balance and transfer tokens with private key', async ({ page }) => {
    await appVcrInsertCassette('balance_transfer', { allow_playback_repeats: true })
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn?testnet=true');
    await expect(page.locator('body')).toContainText('₿0.00018709', { timeout: 10_000 });
    await expect(page).toHaveURL(/step=1/);
    await expect(page.getByRole('button', { name: "Next →" })).toBeEnabled();
    await page.getByRole('button', { name: "Next →" }).click();
    await page.locator('#hong_bao_private_key').fill('someprivatekey');
    await expect(page.getByText('Invalid private key format')).toBeVisible();
    await expect(page.getByRole('button', { name: "Continue" })).toBeDisabled();
    await page.locator('#hong_bao_private_key').fill('cMevyXEL8C1ddb7v8hQQZgpcPPNYejS1eR4tqUAV4u4MNf4KLPnK');
    await expect(page.getByText('Invalid private key format')).toBeHidden();
    await expect(page.getByRole('button', { name: "Continue" })).toBeEnabled();
    await page.getByRole('button', { name: "Continue" }).click();
    await expect(page.getByText('Enter Destination')).toBeVisible();
    await page.locator('#hong_bao_to_address').fill('tb1qcggwu7s8gkz6snsd6zsyxfe4v0t08ysq7s90u0');
    await page.locator('label').filter({ hasText: 'Slow' }).click();
    await page.getByRole('button', { name: "Transfer" }).click();
    await expect(page.getByText('Your transaction has been submitted to the network.')).toBeVisible();
  });

  test('user can check balance and transfer tokens with mnemonic', async ({ page }) => {
    await appVcrInsertCassette('balance_transfer', { allow_playback_repeats: true })
    // await appVcrInsertCassette('balance_transfer', { allow_playback_repeats: true, record: 'all' })
    await page.goto('/hong_baos/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn');
    await expect(page.locator('body')).toContainText('₿0.0002');
    await expect(page).toHaveURL(/step=1/);
    await page.getByRole('button', { name: "Next →" }).click();
    await page.getByRole('button', { name: "24 Words" }).click();
    await page.waitForTimeout(1_000); // wait for js to fully load
    await fillMnemonic(page, "tilt cinnamon stick voice other pulse print rain broken man frost library chunk element leader side acquire copy code east abandon then dose smooth");
    await page.getByRole('button', { name: "Continue" }).click();
    await expect(page.getByText('Enter Destination')).toBeVisible();
    await page.waitForTimeout(2_000); // wait utxos to be loaded
    await page.locator('#hong_bao_to_address').fill('tb1qcggwu7s8gkz6snsd6zsyxfe4v0t08ysq7s90u0');
    await page.locator('label').filter({ hasText: 'Slow' }).click();
    await page.getByRole('button', { name: "Transfer" }).click();
    await expect(page.getByText('Your transaction has been submitted to the network.')).toBeVisible();
  });

  // if tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn doesnt have funds (uxtos), unskip this test to reload previous address + record: all
  test('user can check balance and transfer tokens with mnemonic 2', async ({ page }) => {
    test.skip('only to transfer back BTC to tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn')
    await appVcrInsertCassette('balance_transfer_2', { allow_playback_repeats: true, record: 'all' })
    await page.goto('/hong_baos/tb1qcggwu7s8gkz6snsd6zsyxfe4v0t08ysq7s90u0');
    await expect(page).toHaveURL(/step=1/);
    await page.getByRole('button', { name: "Next →" }).click();
    await page.getByRole('button', { name: "24 Words" }).click();
    await page.waitForTimeout(1_000); // wait for js to fully load
    await fillMnemonic(page, "range crucial fever correct tortoise zero unveil sell inmate robust magic soccer wood estate reunion rival flame usage around tent pony quality client process");
    await page.getByRole('button', { name: "Continue" }).click();
    await expect(page.getByText('Enter Destination')).toBeVisible();
    await page.waitForTimeout(3_000); // wait utxos to be loaded
    await page.locator('#hong_bao_to_address').fill('tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn');
    await page.locator('label').filter({ hasText: 'Slow' }).click();
    await page.getByRole('button', { name: "Transfer" }).click();
    await expect(page.getByText('Your transaction has been submitted to the network.')).toBeVisible();
  });


});