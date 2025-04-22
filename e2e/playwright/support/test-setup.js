import { test as base, expect } from '@playwright/test';
import { app, appVcrEjectCassette } from './on-rails'; // Assuming on-rails.js is in the same directory

// Setup global before each / after each https://playwrightsolutions.com/how-do-you-set-hooks-before-or-after-each-spec-globally-in-playwright-test/
// Extend the base test to include setup and teardown for every test using an auto-use fixture
const test = base.extend({
  // This is an auto-use fixture. It runs before each test using this 'test' instance.
  // The 'await use()' part runs the actual test. Code after 'use()' runs as teardown.
  autoSetupTeardown: [async ({}, use, testInfo) => {
    // --- BeforeEach ---
    console.log(`[test-setup/auto] Running BeforeEach for ${testInfo.title}: clean + fixtures`);
    try {
      await app('clean');
      await app('activerecord_fixtures');
    } catch (error) {
      console.error(`[test-setup/auto] Error during BeforeEach for ${testInfo.title}:`, error);
      throw error; // Re-throw to fail the test if setup fails
    }

    // Run the test itself
    await use();

    // --- AfterEach ---
    console.log(`[test-setup/auto] Running AfterEach for ${testInfo.title}: ejecting cassette`);
    try {
      await appVcrEjectCassette();
    } catch (error) {
      console.error(`[test-setup/auto] Error during AfterEach for ${testInfo.title}:`, error);
      // Decide if teardown errors should fail the test run
      // throw error;
    }
  }, { auto: true }], // 'auto: true' ensures this fixture runs automatically
});

// Export the extended test instance and expect for use in spec files
export { test, expect };