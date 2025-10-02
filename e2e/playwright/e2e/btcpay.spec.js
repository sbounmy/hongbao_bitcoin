import { test, expect } from '../support/test-setup';
import { appVcrInsertCassette, appVcrEjectCassette, appGetCredentials } from '../support/on-rails';

test.describe('BTCPay Checkout Flow', () => {
  // Helper function to fill buyer information
  async function fillBuyerInformation(page) {
    // Only fill email if it's not readonly (i.e., user is not logged in)
    const emailField = page.locator('#buyerEmail');
    const isReadonly = await emailField.getAttribute('readonly');
    if (isReadonly === null) {
      await emailField.fill('test@example.com');
    }

    // First and last name
    await page.locator('#buyerFirstName').fill('Satoshi');
    await page.locator('#buyerLastName').fill('Nakamoto');

    // Address fields
    await page.locator('#buyerAddress1').fill('123 Bitcoin Plaza');
    await page.locator('#buyerAddress2').fill('Apartment 21');
    await page.locator('#buyerZip').fill('75001');
    await page.locator('#buyerCity').fill('Paris');
    await page.locator('#buyerState').fill('Île-de-France');

    // Phone at the end
    await page.locator('#buyerPhone').fill('+33612345678');
  }

  // Helper function to handle BTCPay payment
  async function handleBTCPayPayment(page, context, btcpayServerUrl, btcpayCredentials, paymentMethod) {
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

    await expect(btcPayPage.locator('body')).toContainText('Wallet Balance');
    if (paymentMethod === 'bitcoin') {
      if (await btcPayPage.locator("#mainMenuToggle").isVisible()) {
        await btcPayPage.locator("#mainMenuToggle").click();
      } // when mobile

      await btcPayPage.locator('#StoreNav-WalletBTC').click();
      await expect(btcPayPage.locator('body')).toContainText('hongbaotest BTC Wallet');

      if (await btcPayPage.locator("#mainMenuToggle").isVisible()) {
        await btcPayPage.locator("#mainMenuToggle").click();
      } // when mobile
      await btcPayPage.locator('#WalletNav-Send').click();

      // Fill the destination address
      await btcPayPage.locator('#Outputs_0__DestinationAddress').fill(btcAddress);
      await btcPayPage.locator('#Outputs_0__Amount').fill(amountDue);

      // Sign transaction
      await btcPayPage.locator('#SignTransaction').click();

      // Wait for the broadcast button to be available and click it
      await btcPayPage.waitForSelector('#BroadcastTransaction', { state: 'visible' });
      await btcPayPage.locator('#BroadcastTransaction').click();
    } else if (paymentMethod === 'lightning') {
      // to be implemented
    }

    // Close BTCPay tab
    await btcPayPage.close();

    // Go back to payment page
    await page.bringToFront();
  }

  // Parameterized tests for different payment methods
  const paymentMethods = [
    { name: 'Bitcoin', buttonText: /Buy with Bitcoin/, cassette: 'btcpay_checkout_bitcoin', method: 'bitcoin' },
    //{ name: 'Lightning', buttonText: /Buy with Lightning/, cassette: 'btcpay_checkout_lightning', method: 'lightning' } // skip for now
  ];

  paymentMethods.forEach(({ name, buttonText, cassette, method }) => {
    test(`logged in user can initiate a purchase with BTCPay ${name}`, async ({ page, context }) => {
      test.setTimeout(180_000); // 3 minutes for payment flow
      const btcpayCredentials = await appGetCredentials('btcpay');
      const btcpayServerUrl = `https://${process.env.BTCPAY_HOST}`;

      console.log(`Using BTCPay Server URL: ${btcpayServerUrl} for ${name} payment`);

      // Use VCR to record/replay the interaction with the BTCPay Server API
      await appVcrInsertCassette(cassette, { allow_playback_repeats: true });

      await page.goto('/');

      // Choose a plan
      await page.locator('label').filter({ hasText: /Mini Pack/ }).click();

      // Click the appropriate payment button
      await page.locator('button').filter({ hasText: buttonText }).click();

      // Fill buyer information
      await fillBuyerInformation(page);

      await page.getByRole('button', { name: 'Continue to Payment' }).click();

      // Gets redirected to third party (btcpay) host
      expect(page.url()).toContain(btcpayServerUrl);

      // Handle payment based on method
      await handleBTCPayPayment(page, context, btcpayServerUrl, btcpayCredentials, method);

      // Wait for "Payment Received" to appear
      await expect(page.locator('h4').filter({ hasText: 'Payment Received' })).toBeVisible({ timeout: 90000 });

      await page.getByRole('link').filter({ hasText: /Return to/ }).click();

      // Verify redirection back to the app
      await expect(page).toHaveURL(/.*\/checkout\/success/);

      // It will show order not found because webhooks are not processed in this test
      // so we will just check if the page is loaded

      // Eject the VCR cassette to save the recording
      await appVcrEjectCassette();
    });
  });

  test('place autocomplete works', async ({ page }) => {
    await page.goto('/pricing');

    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    await page.locator('button').filter({ hasText: /Buy with Bitcoin/ }).click();

    await page.locator('#buyerAddress1').click();
    await page.waitForTimeout(1_000);
    await page.locator('#buyerAddress1').pressSequentially('1 rue de la paix');
    await page.waitForTimeout(1_000);
    if (await page.locator('.pac-item').first().isHidden()) {
      await page.locator('#buyerAddress1').click()
    }
    await page.locator('.pac-item:visible').first().click();
    await page.waitForTimeout(1_000);
    await expect(page.locator('#buyerAddress1')).toHaveValue('1 Rue de la Paix');
    await expect(page.locator('#buyerCity')).toHaveValue('Paris');
    await expect(page.locator('#buyerState')).toHaveValue('Île-de-France');
    await expect(page.locator('#buyerZip')).toHaveValue('75001');
    await expect(page.locator('#buyerCountry')).toHaveValue('FR');

    // resets when changing country
    await page.locator('#buyerCountry').selectOption('US');
    await expect(page.locator('#buyerAddress1')).toHaveValue('');
    await expect(page.locator('#buyerCity')).toHaveValue('');
    await expect(page.locator('#buyerState')).toHaveValue('');
    await expect(page.locator('#buyerZip')).toHaveValue('');
    await expect(page.locator('#buyerCountry')).toHaveValue('US');
  });

  test('places restricts to country', async ({ page }) => {
    await page.goto('/pricing');

    await page.locator('label').filter({ hasText: /Mini Pack/ }).click();
    await page.locator('button').filter({ hasText: /Buy with Bitcoin/ }).click();

    await page.locator('#buyerCountry').selectOption('US');

    await page.locator('#buyerAddress1').click();
    await page.waitForTimeout(1_000);
    await page.locator('#buyerAddress1').pressSequentially('1 rue de la paix');
    await page.waitForTimeout(1_000);
    if (await page.locator('.pac-item').first().isHidden()) {
      await page.locator('#buyerAddress1').click()
    }
    await page.locator('.pac-item:visible').first().click();
    await page.waitForTimeout(1_000);
    await expect(page.locator('#buyerAddress1')).toHaveValue('1 Rue De La Paix');
    await expect(page.locator('#buyerCity')).toHaveValue('Cloudcroft');
    await expect(page.locator('#buyerState')).toHaveValue('New Mexico');
    await expect(page.locator('#buyerZip')).toHaveValue('88317');
    await expect(page.locator('#buyerCountry')).toHaveValue('US');
  });
});