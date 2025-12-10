import { test, expect } from '../support/test-setup';
import { app, forceLogin, appVcrInsertCassette, appVcrEjectCassette, appFactories } from '../support/on-rails';

test.describe('Explore', () => {
  test('user can explore papers', async ({ page }) => {
    await page.goto('/papers/explore');
    await expect(page.locator('body')).toContainText('Explore');
    await expect(page.locator('.papers-item-component')).toHaveCount(3);
  });

  test.describe('Infinity Scroll', () => {
    test.beforeEach(async () => {
      await appFactories([
        ['create_list', 'paper', 25, {
          active: true,
          image_front: null,
          image_back: null
        }]
      ]);
    });

    test('loads initial papers and shows loader', async ({ page }) => {
      await page.goto('/papers/explore');

      const papers = page.locator('.papers-item-component');
      await expect(papers).toHaveCount(20);

      const loaderFrame = page.locator('[id^="papers_page_"]');
      await expect(loaderFrame).toBeVisible();
    });

    test('loads more papers when scrolling to bottom', async ({ page }) => {
      await page.goto('/papers/explore');

      const papers = page.locator('.papers-item-component');
      await expect(papers).toHaveCount(20);

      const loaderFrame = page.locator('[id^="papers_page_"]');
      await expect(loaderFrame).toBeVisible();

      await loaderFrame.scrollIntoViewIfNeeded();

      await expect(page.locator('.loading.loading-spinner')).toBeVisible();

      await page.waitForFunction(
        () => {
          const currentPapers = document.querySelectorAll('.papers-item-component');
          return currentPapers.length > 20;
        },
        { timeout: 10000 }
      );

      await expect(papers).toHaveCount(28);

      await expect(loaderFrame).not.toBeVisible();
    });
  });
});
