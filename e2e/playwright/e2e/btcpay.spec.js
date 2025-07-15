import { test, expect } from '../support/test-setup';
import { appVcrInsertCassette, appVcrEjectCassette, appGetCredentials } from '../support/on-rails';

test.describe('BTCPay Checkout Flow', () => {
  test('logged in user can initiate a purchase with BTCPay ON CHAIN', async ({ page, context }) => {
    test.setTimeout(180_000); // 3 minutes for payment flow
    const btcpayCredentials = await appGetCredentials('btcpay');
    const btcpayServerUrl = "https://testnet.demo.btcpayserver.org";
    
    // Use VCR to record/replay the interaction with the BTCPay Server API
    await appVcrInsertCassette('btcpay_checkout_wallet_transfer', { allow_playback_repeats: true});

    await page.goto('/');
    
    // Choose a plan
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();

    // Click buy with BTC button
    const btcpayForm = page.locator('form:has(input[name="provider"][value="btcpay"])');
    await btcpayForm.getByRole('button').click();
    
    // Gets redirected to third party (btcpay) host
    await expect(page.url()).toContain(btcpayServerUrl);
    
    // Click on pay invoice button
    await page.locator('[data-test="form-button"]').click();
    
    // Fill the forms
    await page.locator('#buyerEmail').fill('test@example.com');
    await page.locator('#buyerName').fill('Satoshi Nakamoto');
    await page.locator('#buyerAddress1').fill('123 Bitcoin Plaza');
    await page.locator('#buyerCity').fill('Crypto City');
    await page.locator('#buyerZip').fill('12345');
    await page.locator('#buyerCountry').selectOption('Japan');
    
    // Click on submit
    await page.getByRole('button', { name: 'Submit' }).click();

    // Get the Bitcoin address where money should be sent
    const addressElement = await page.locator('span.truncate-center-text');
    await expect(addressElement).toBeVisible();
    const btcAddress = await addressElement.textContent();

    const amountElement = await page.locator('#AmountDue');
    await expect(amountElement).toBeVisible();
    const amountDue = await amountElement.getAttribute('data-amount-due');

    // Open a new tab to login to BTCPay and send payment
    const btcPayPage = await context.newPage();
    await btcPayPage.goto(btcpayServerUrl);
    
    // Login to BTCPay
    await btcPayPage.locator('#Email').fill(btcpayCredentials.email);
    await btcPayPage.locator('#Password').fill(btcpayCredentials.password);
    await btcPayPage.getByRole('button', { name: 'Sign in' }).click();
    
    // Navigate to Bitcoin wallet
    await btcPayPage.locator('#StoreNav-WalletBTC').click();
    
    // Click on Send
    await btcPayPage.locator('#WalletNav-Send').click();
    
    // Fill the destination address
    await btcPayPage.locator('#Outputs_0__DestinationAddress').fill(btcAddress);
    await btcPayPage.locator('#Outputs_0__Amount').fill(amountDue); // Fill with a small amount for testing
    
    // Sign transaction
    await btcPayPage.locator('#SignTransaction').click();
    
    // Wait for the broadcast button to be available and click it
    await btcPayPage.waitForSelector('#BroadcastTransaction', { state: 'visible' });
    await btcPayPage.locator('#BroadcastTransaction').click();
    
    // Close BTCPay tab
    await btcPayPage.close();
    
    // Go back to payment page and check for payment received
    await page.bringToFront();
    
    // Wait for "Payment Received" to appear
    await expect(page.locator('h4').filter({ hasText: 'Payment Received' })).toBeVisible({ timeout: 90000 });

    // Eject the VCR cassette to save the recording
    await appVcrEjectCassette();
  });
});