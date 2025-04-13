import { test, request, expect } from '@playwright/test'
import config from '../../../playwright.config'

const contextPromise = request.newContext({ baseURL: config.use ? config.use.baseURL : 'http://localhost:5017' })

const appCommands = async (data) => {
  const context = await contextPromise
  const response = await context.post('/__e2e__/command', { data })

  expect(response.ok()).toBeTruthy()
  return response.body
}

const app = (name, options = {}) => appCommands({ name, options }).then((body) => body[0])
const appScenario = (name, options = {}) => app('scenarios/' + name, options)
const appEval = (code) => app('eval', code)
const appFactories = (options) => app('factory_bot', options)

const appVcrInsertCassette = async (cassette_name, options) => {
  const context = await contextPromise;
  if (!options) options = {};

  Object.keys(options).forEach(key => options[key] === undefined ? delete options[key] : {});
  const response = await context.post("/__e2e__/vcr/insert", {data: [cassette_name,options]});
  if (response.ok()) {
    return response.body;
  } else {
    throw new Error(`VCR insert failed with status: ${response.status()} : ${await response.body()}`);
  }
}

const appVcrEjectCassette = async () => {
  const context = await contextPromise;

  const response = await context.post("/__e2e__/vcr/eject");
  expect(response.ok()).toBeTruthy();
  return response.body;
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

// This is to ensure that any cassette is ejected after each test
// test.beforeEach(async () => {
//   await appVcrEjectCassette();
// });

// test.afterEach(async () => {
//   await appVcrEjectCassette();
// });

test.beforeEach(async () => {
  console.log('-------------------clean')
  await app('clean');
  await app('activerecord_fixtures');
});

export { appCommands, app, appScenario, appEval, appFactories, appVcrInsertCassette, appVcrEjectCassette, forceLogin }