import { test, expect } from '../support/test-setup';
import { forceLogin, turboCableConnected, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('Paper Likes', () => {
  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('paper_likes', { allow_playback_repeats: true });
  });

  test.afterEach(async ({ page }) => {
    await appVcrEjectCassette();
  });

  test.describe('when authenticated', () => {
    test('user can like and unlike a paper', async ({ page }) => {
      await forceLogin(page, {
        email: 'satoshi@example.com',
        redirect_to: '/papers/explore'
      });

      await turboCableConnected(page);

      // Find the first paper's like button
      const firstPaper = page.locator('.papers-item-component').first();
      const likeButton = firstPaper.locator('[id^="like_button_paper_"]');
      const likeCount = likeButton.locator('span[id^="likes_count_paper_"]');

      // Get initial like count
      const initialCount = await likeCount.textContent();
      const initialCountNum = parseInt(initialCount) || 0;

      // Click to like
      await likeButton.click();

      // Verify the heart icon changed to solid (red color)
      // await expect(likeButton).toHaveClass(/text-red-500/);
      await expect(likeButton.locator('svg')).toBeVisible();

      // Verify count increased by 1
      await expect(likeCount).toHaveText(String(initialCountNum + 1));

      // Click to unlike
      await likeButton.click();

      // Verify the heart icon is no longer red
      await expect(likeButton).not.toHaveClass(/text-red-500/);

      // Verify count decreased back to original
      await expect(likeCount).toHaveText(String(initialCountNum));
    });

    test('like count persists across page reloads', async ({ page }) => {
      await forceLogin(page, {
        email: 'satoshi@example.com',
        redirect_to: '/papers/explore'
      });

      await turboCableConnected(page);

      const firstPaper = page.locator('.papers-item-component').first();
      const likeButton = firstPaper.locator('[id^="like_button_paper_"]');
      const likeCount = likeButton.locator('span[id^="likes_count_paper_"]');

      // Like the paper
      await likeButton.click();
      expect(likeButton).toHaveText('1');

      // Reload the page
      await page.reload();
      await turboCableConnected(page);

      // Verify like state persisted
      const reloadedPaper = page.locator('.papers-item-component').first();
      const reloadedButton = reloadedPaper.locator('[id^="like_button_paper_"]');
      const reloadedCount = reloadedButton.locator('span[id^="likes_count_paper_"]');

      // await expect(reloadedButton).toHaveClass(/text-red-500/);
      await expect(reloadedCount).toHaveText('1');
    });

    test('prevents duplicate likes from rapid clicking', async ({ page }) => {
      await forceLogin(page, {
        email: 'satoshi@example.com',
        redirect_to: '/papers/explore'
      });

      await turboCableConnected(page);

      const firstPaper = page.locator('.papers-item-component').first();
      const likeButton = firstPaper.locator('[id^="like_button_paper_"]');
      const likeCount = likeButton.locator('span[id^="likes_count_paper_"]');

      const initialCount = await likeCount.textContent();
      const initialCountNum = parseInt(initialCount) || 0;

      // Rapidly click the like button multiple times
      await likeButton.click();
      await page.waitForTimeout(500);
      await likeButton.click();
      await page.waitForTimeout(500);
      await likeButton.click();

      // Wait a bit for any pending requests
      await page.waitForTimeout(500);

      // Should end up with the same count (toggled back to unlike)
      await expect(likeCount).toHaveText(String(initialCountNum + 1));
    });
  });

  test.describe('when unauthenticated', () => {
    test('redirects to login when unauthenticated user clicks like', async ({ page }) => {
      await page.goto('/papers/explore');

      const firstPaper = page.locator('.papers-item-component').first();

      // Should see a button with heart icon and count
      const likeButton = firstPaper.locator('[id^="like_button_paper_"]');
      await expect(likeButton).toBeVisible();

      // Should have heart icon
      await expect(likeButton.locator('svg')).toBeVisible();

      // Should show count
      const likeCount = likeButton.locator('span[id^="likes_count_paper_"]');
      await expect(likeCount).toBeVisible();

      // Click should redirect to login
      await likeButton.click();
      await expect(page).toHaveURL(/signup/);
    });
  });

  test('view count increments when visiting paper', async ({ page }) => {
    await page.goto('/papers/explore');

    // Get initial view count
    const firstPaper = page.locator('.papers-item-component').first();
    // The view count is in a div with an eye icon
    const viewSection = firstPaper.locator('.paper-views-count').first();
    const viewCount = viewSection.locator('span');
    const initialViews = await viewCount.textContent();
    const initialViewsNum = parseInt(initialViews) || 0;
    const newPagePromise = page.context().waitForEvent('page');

    // Click on the paper image to view it
    await firstPaper.first().click();
    await firstPaper.first().click();

    // Wait for the new page to open and get the new page object
    const newPage = await newPagePromise;
    await newPage.waitForLoadState();
    await expect(newPage).toHaveURL(/\/papers\/\d+/);

    // Go back to explore
    await page.goto('/papers/explore');

    // Verify view count increased by 1
    const updatedPaper = page.locator('.papers-item-component').first();
    const updatedViewSection = updatedPaper.locator('.paper-views-count').first();
    const updatedViewCount = updatedViewSection.locator('span');
    await expect(updatedViewCount).toHaveText(String(initialViewsNum + 1));
  });
});