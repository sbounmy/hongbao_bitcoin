import { test, expect } from '../support/test-setup';

test.describe('Topup', () => {
  test('user can topup', async ({ page }) => {
    await page.goto('/en/papers/1?step=4');

    const input = page.locator('.input-public-address:visible');
    await expect(input).toHaveCount(1);
    await expect(input).toHaveValue(/^bc1q/);

    const address = await input.inputValue();

    console.log(address);
    await expect(page.getByRole('link', { name: 'Verify funds' })).toHaveAttribute('href', `https://mempool.space/address/${address}`);
    await page.locator("label", { has: page.locator('#hong_bao_payment_method_id_1') }).click();

    const iframe = page.locator("#payment_method_credit_card iframe").contentFrame();
    await iframe.getByText('Buy BTC').click();

    await expect(iframe.getByRole('button', { name: 'Next' })).toBeVisible();
    // todo: on the iframe it asks to sign up via OTP SMS... cant test right now if we properly send the correct address to mt pelerin
    // await expect(page.getByText('You are about to add bc1qgn...palwlw to your profile')).toBeVisible();


  });
});