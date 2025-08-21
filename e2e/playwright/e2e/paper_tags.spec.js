import { test, expect } from '../support/test-setup';
import { forceLogin  } from '../support/on-rails';

test.describe('Paper Tags - Featured Section', () => {
  test('should display paper with featured tag in Featured section', async ({ page }) => {
    await page.goto('/dashboard');

    expect(page.locator('#papers > div:nth-child(3)')).toContainText("Pizza Day");
  });

  test('should not display paper in Featured section after removing featured tag', async ({ page }) => {
    await forceLogin(page, {
      email: 'admin@example.com',
      redirect_to: '/admin/papers/2/edit'
    });

    // Unselect the featured tag
    const tagSelect = page.locator('select[name="paper[tag_ids][]"]');
    await tagSelect.selectOption([]); // Deselect all

    // Save the paper
    await page.getByRole('button', { name: /Update Paper/i }).click();

    // Navigate to the public papers page
    await page.goto('/dashboard');

    expect(page.locator('#papers > div:nth-child(3)')).not.toContainText("Pizza Day");
  });
});