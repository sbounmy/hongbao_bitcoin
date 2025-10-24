import { test, expect } from '../support/test-setup';
import { forceLogin  } from '../support/on-rails';

test.describe('Paper Tags - Featured Section', () => {
  test('should display paper with featured tag in Featured section', async ({ page }) => {
    await page.goto('/dashboard');

    await expect(page.locator('body')).toContainText('Buy traditional red envelopes');
    await page.getByText('Buy traditional red envelopes').click(); // hide this
    await expect(page.locator('#featured')).toContainText("Pizza Day");
  });

  test('should not display paper in Featured section after removing featured tag', async ({ page }) => {
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/papers/2/edit'
    });

    await expect(page.locator('body')).toContainText('featured');
    // Unselect the featured tag
    const tagSelect = page.locator('select[name="paper[tag_ids][]"]');
    await tagSelect.selectOption([]); // Deselect all

    // Save the paper
    await page.getByRole('button', { name: /Update Paper/i }).click();

    await expect(page.locator('body')).toContainText('Paper was successfully updated.');
    await expect(page.locator('body')).not.toContainText('featured');

    // Navigate to the public papers page
    await page.goto('/dashboard');

    await page.getByText('Buy traditional red envelopes').click(); // hide this
    await expect(page.locator('#featured')).not.toContainText("Pizza Day");
  });
});