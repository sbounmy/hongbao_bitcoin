import { test as setup, expect } from '@playwright/test';

// https://github.com/shakacode/cypress-playwright-on-rails/commit/b0311e704e9cab1f7ebe6cd88cfdd677dab19e15
setup('disarm vcr middleware bug', async ({ page }) => {
  // This request "disarms" the VCR middleware bug before any tests run.
  console.log('disarm vcr middleware bug');
  await page.goto('/up');
});

export default setup;