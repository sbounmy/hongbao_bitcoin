import { expect, request } from '@playwright/test'
import config from '../../../playwright.config'

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

  const response = await page.request.post('/__e2e__/force_login', {
      data: { email: email, redirect_to: redirect_to },
      headers: { 'Content-Type': 'application/json' }
  });

  // Handle response based on status code
  if (response.ok()) {
      await page.goto(redirect_to);
  } else {
      // Throw an exception for specific error statuses
      throw new Error(`Login failed with status: ${response.status()} : ${await response.body()}`);
  }
}

const turboCableConnected = async (page) => {
  for (const stream of await page.locator('turbo-cable-stream-source').all()) {
    await expect(stream).toHaveAttribute('connected');
  }
}

import fs from 'fs/promises';
import path from 'path';
import os from 'os';
import { pathToFileURL } from 'url';
import scrape from 'website-scraper';

const savePageAs = async (page, context, callback) => {
  let baseTempDir;
  try {
    // 1. Create a base temporary directory
    baseTempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'playwright-scrapebase-'));
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
          await fs.rm(baseTempDir, { recursive: true, force: true });
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
          await fs.rm(baseTempDir, { recursive: true, force: true });
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
        await fs.rm(baseTempDir, { recursive: true, force: true });
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
  await page.fill('input[name="phoneNumber"]', '2015550123');
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

export { appCommands, appGetCredentials, app, appScenario, appEval, appFactories, appVcrInsertCassette, appVcrEjectCassette, forceLogin, turboCableConnected, savePageAs, fillCheckout }