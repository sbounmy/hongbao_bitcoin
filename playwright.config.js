// @ts-check
import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
import dotenv from 'dotenv';
import path from 'path';
dotenv.config({ path: path.resolve(__dirname, '.env.test') });

// Is this a parallel run orchestrated by our Rake task?
const isParallelRun = !!process.env.E2E_PARALLEL_RUN;

/**
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './e2e/playwright/e2e',
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: isParallelRun ? 'blob' : 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // For parallel runs, use the BASE_URL from the Rake task.
    // For standard runs, fallback to the existing logic.
    baseURL: (() => {
      // For CI/prod, a full BASE_URL (e.g., https://staging.myapp.com) is often provided.
      if (process.env.BASE_URL) {
        return process.env.BASE_URL;
      }

      // For local development, determine protocol based on hostname.
      const host = process.env.APP_HOST || 'localhost:3003';
      const protocol = host.includes('localhost') ? 'http' : 'https';
      return `${protocol}://${host}`;
    })(),

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    // Connect to Playwright container
    // connectOptions: {
    //   wsEndpoint: `ws://${process.env.PLAYWRIGHT_CONTAINER}:3000`
    // }
  },

  /* Configure projects for major browsers */
  projects: [
    // This project runs once before all tests to disarm a VCR bug.
    {
      name: 'setup',
      testDir: './e2e/playwright/support',
      testMatch: /global-setup\.js/,
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], bypassCSP: true, launchOptions: { args: ['--disable-web-security']} },
      dependencies: ['setup'],
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'], bypassCSP: true },
      dependencies: ['setup'],
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'], bypassCSP: true },
      dependencies: ['setup'],
    },

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'], bypassCSP: true },
    // },

    /* Test against branded browsers. */
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
    // {
    //   name: 'Google Chrome',
    //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    // },
  ],

  // Only use the webServer for standard, non-parallel runs.
  // The Rake task handles server management for parallel runs.
  webServer: isParallelRun ? undefined : {
    command: 'APP_PORT=3003 STRIPE_CONTEXT_ID=localhost_1 bundle exec foreman start -f Procfile.test',
    port: 3003,
    reuseExistingServer: !process.env.CI,
    timeout: 120000, // 2 minutes for slow Rails boot
    stdout: 'pipe',
    stderr: 'pipe'
  },
});

