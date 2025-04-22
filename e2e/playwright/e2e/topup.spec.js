import { test, expect } from '../support/test-setup';

test.describe('Topup', () => {
  test('user can topup', async ({ page }) => {
    await page.goto('/en/papers/2?step=2');

    await expect(page.locator('[data-binding-name-value="publicAddressText"]:visible')).toHaveValue(/^bc1q/);

    const address = await page.locator('[data-binding-name-value="publicAddressText"]:visible').inputValue();

    console.log(address);
    await page.locator("label", { has: page.locator('#hong_bao_payment_method_id_1') }).click();

    const iframe = page.locator("iframe[data-mt-pelerin-target='iframe']").contentFrame();
    await iframe.getByText('Buy BTC').click();

    await expect(iframe.getByRole('button', { name: 'Next' })).toBeVisible();
    // todo: on the iframe it asks to sign up via OTP SMS... cant test right now if we properly send the correct address to mt pelerin
    // await expect(page.getByText('You are about to add bc1qgn...palwlw to your profile')).toBeVisible();
  });
});