import { test, expect } from '../support/test-setup';
import { appVcrInsertCassette, appVcrEjectCassette, appGetCredentials } from '../support/on-rails';

test.describe('BTCPay Checkout Flow', () => {
  test('logged in user can initiate a purchase with BTCPay ON CHAIN', async ({ page, context }) => {
    test.setTimeout(180_000); // 3 minutes for payment flow
    const btcpayCredentials = await appGetCredentials('btcpay');
    const btcpayServerUrl = `https://${process.env.BTCPAY_HOST}`
    
    console.log(`Using BTCPay Server URL: ${btcpayServerUrl}`);
    // Use VCR to record/replay the interaction with the BTCPay Server API
    await appVcrInsertCassette('btcpay_checkout_wallet_transfer', { allow_playback_repeats: true});

    await page.goto('/');
    
    // Choose a plan
    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();

    // Click buy with BTC button
    await page.locator('button').filter({ hasText: /Buy with Bitcoin/ }).click();

    await page.locator('#buyerEmail').fill('test@example.com');
    await page.locator('#buyerName').fill('Satoshi Nakamoto');
    await page.locator('#buyerAddress1').fill('123 Bitcoin Plaza');
    await page.locator('#buyerCity').fill('Crypto City');
    await page.locator('#buyerZip').fill('12345');
    await page.locator('#buyerCountry').selectOption('Japan');
    await page.locator('#buyerState').fill('Tokyo');
    

    await page.getByRole('button', { name: 'Continue to Payment' }).click();
    
    // Gets redirected to third party (btcpay) host
    await expect(page.url()).toContain(btcpayServerUrl);

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

    await page.getByRole('link').filter({ hasText: /Return to/ }).click();

    // verify here if he is back to the app
    await expect(page).toHaveURL(/.*\/checkout\/success/);
    
    // it will show order not found because webhooks are not processed in this test
    // so we will just check if the page is loaded

    // Eject the VCR cassette to save the recording
    await appVcrEjectCassette();
  });
});