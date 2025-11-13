import { expect, request } from '@playwright/test'
import config from '../../../playwright.config'
import fs from 'fs'
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs'

const contextPromise = request.newContext({ baseURL: config.use ? config.use.baseURL : 'http://localhost:5017' })

const appCommands = async (data) => {
  const context = await contextPromise
  const response = await context.post('/__e2e__/command', { data })

  if (response.ok()) {
    console.log('[AppCommand] Command executed: ', data)
    const contentType = response.headers()['content-type'];
    if (contentType && contentType.includes('application/json')) {
      // If the response is JSON, parse it as JSON.
      return await response.json();
    } else {
      return await response.body();
    }
  } else {
    throw new Error(`Command failed with status: ${response.status()} : ${response.body()}`);
  }
}

const app = (name, options = {}) => appCommands({ name, options }).then((body) => body[0])
const appScenario = (name, options = {}) => app('scenarios/' + name, options)
const appEval = (code) => app('eval', code)
const appFactories = (options) => app('factory_bot', options)

const appGetCredentials = (key) => app('get_credentials', key)

const appVcrInsertCassette = async (cassette_name, options) => {
  const context = await contextPromise;
  if (!options) options = {};

  Object.keys(options).forEach(key => options[key] === undefined ? delete options[key] : {});
  const response = await context.post("/__e2e__/vcr/insert", {data: [cassette_name,options]});
  if (response.ok()) {
    console.log('[VCR] Inserted cassette: ', cassette_name)
    return await response.body();
  } else {
    throw new Error(`VCR insert failed with status: ${response.status()} : ${await response.body()}`);
  }
}

const appVcrEjectCassette = async () => {
  const context = await contextPromise;

  const response = await context.post("/__e2e__/vcr/eject");
  if (response.ok()) {
    console.log('[VCR] Ejected cassette... ')
    return await response.body();
  } else {
    throw new Error(`VCR eject failed with status: ${response.status()} : ${await response.body()}`);
  }
}

const forceLogin = async (page, { email, redirect_to = '/' }) => {
  // Validate inputs
  if (typeof email !== 'string'  || typeof redirect_to !== 'string') {
      throw new Error('Invalid input: email and redirect_to must be non-empty strings');
  }

  // Build URL with query parameters
  const params = new URLSearchParams({
    email: email,
    redirect_to: redirect_to
  });

  // Simply navigate to the force_login URL - the browser will handle cookies naturally
  await page.goto(`/__e2e__/force_login?${params.toString()}`);
}

const turboCableConnected = async (page) => {
  for (const stream of await page.locator('turbo-cable-stream-source').all()) {
    await expect(stream).toHaveAttribute('connected');
  }
}

import fsPromises from 'fs/promises';
import path from 'path';
import os from 'os';
import { pathToFileURL } from 'url';
import scrape from 'website-scraper';

const savePageAs = async (page, context, callback) => {
  let baseTempDir;
  try {
    // 1. Create a base temporary directory
    baseTempDir = await fsPromises.mkdtemp(path.join(os.tmpdir(), 'playwright-scrapebase-'));
    const scraperTargetDirectory = path.join(baseTempDir, 'scraped-site');

    // 2. Scrape the page content with assets
    let scrapeResult;
    try {
      scrapeResult = await scrape({
        urls: [page.url()],
        directory: scraperTargetDirectory,
      });
    } catch (error) {
      console.error(`Failed to scrape page ${pageUrl}:`, error);
      // Attempt cleanup even on scrape failure, then re-throw to fail the test
      if (baseTempDir) {
        try {
          await fsPromises.rm(baseTempDir, { recursive: true, force: true });
        } catch (cleanupError) {
          console.error('Error during cleanup after scrape failure:', cleanupError);
        }
      }
      throw error;
    }

    if (!scrapeResult || scrapeResult.length === 0 || !scrapeResult[0].filename) {
      throw new Error('Website-scraper did not return the expected result or filename.');
    }

    // 3. Determine the path to the main saved HTML file
    const mainHtmlFile = scrapeResult[0].filename;
    const localHtmlPath = path.join(scraperTargetDirectory, mainHtmlFile);
    const fileUrl = pathToFileURL(localHtmlPath).href;

    // 4. Open the local HTML file in a new page
    const offlinePage = await context.newPage();

    try {
      await offlinePage.goto(fileUrl, { waitUntil: 'domcontentloaded' });
    } catch (error) {
      console.error(`Failed to load local HTML file ${fileUrl}:`, error);
      // Attempt cleanup even on goto failure, then re-throw
      if (baseTempDir) {
        try {
          await fsPromises.rm(baseTempDir, { recursive: true, force: true });
        } catch (cleanupError) {
          console.error('Error during cleanup after goto failure:', cleanupError);
        }
      }
      throw error;
    }
    // context.setOffline(true);
    await callback(offlinePage);
    // context.setOffline(false);
    await offlinePage.close();

  } finally {
    // 7. Clean up: remove the temporary directory and its contents
    if (baseTempDir) {
      try {
        await fsPromises.rm(baseTempDir, { recursive: true, force: true });
      } catch (e) {
        console.error(`Failed to remove temporary directory ${baseTempDir}:`, e);
      }
    }
  }
}

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

const fillCheckout = async (page) => {
  const random = getRandomInt(9999);
  await page.fill('input[name="shippingName"]', `Satoshi Nakamoto ${random}`);
  if (await page.getByText("Enter address manually").isVisible()) {
    await page.getByText("Enter address manually").click();
  }
  await page.fill('input[name="shippingAddressLine1"]', '123 Main St');
  await page.fill('input[name="shippingPostalCode"]', '94107');
  await page.fill('input[name="shippingLocality"]', 'San Francisco');
  await page.selectOption('.PhoneNumberCountryCodeSelect-select', 'FR');
  await page.fill('input[name="phoneNumber"]', '651234567');
  await page.selectOption('select[name="shippingCountry"]', 'US');
  await page.selectOption('select[name="shippingAdministrativeArea"]', 'CA');

  if (await page.locator('input[name="cardNumber"]').isVisible()) {
    await page.fill('input[name="cardNumber"]', '4242424242424242'); // Stripe test card
    await page.fill('input[name="cardExpiry"]', '12/2034'); // Future date
    await page.fill('input[name="cardCvc"]', '123');
  }

  if (await page.locator('#enableStripePass').isChecked()) {
    await page.locator('#enableStripePass').uncheck();
  }
};

// Timecop helper for freezing/unfreezing time in tests
const timecop = async (dateOrAction) => {
  if (dateOrAction === 'return' || dateOrAction === 'unfreeze') {
    return app('timecop', { action: 'return' });
  } else {
    return app('timecop', { action: 'freeze', date: dateOrAction });
  }
};

timecop.freeze = async (date) => app('timecop', { action: 'freeze', date });
timecop.return = async () => app('timecop', { action: 'return' });
timecop.travel = async (date) => app('timecop', { action: 'travel', date });

// Helper function to authenticate and read encrypted PDFs
const authenticatePDF = async (filePath, password) => {
  try {
    // Read the PDF file
    const dataBuffer = fs.readFileSync(filePath);

    // Convert Buffer to Uint8Array for pdfjs-dist
    const uint8Array = new Uint8Array(dataBuffer);

    // Try to read the PDF with the provided password
    const pdfDoc = await getDocument({
      data: uint8Array,
      password: password
    }).promise;

    // Extract text from all pages
    let fullText = '';
    for (let pageNum = 1; pageNum <= pdfDoc.numPages; pageNum++) {
      const page = await pdfDoc.getPage(pageNum);
      const textContent = await page.getTextContent();
      const pageText = textContent.items.map(item => item.str).join(' ');
      fullText += pageText + ' ';
    }

    return {
      success: true,
      content: fullText.trim(),
      numPages: pdfDoc.numPages
    };
  } catch (error) {
    // If password is wrong or any other error occurs
    return {
      success: false,
      content: null,
      error: error.message
    };
  }
};

export { appCommands, appGetCredentials, app, appScenario, appEval, appFactories, appVcrInsertCassette, appVcrEjectCassette, forceLogin, turboCableConnected, savePageAs, fillCheckout, timecop, authenticatePDF, fs }