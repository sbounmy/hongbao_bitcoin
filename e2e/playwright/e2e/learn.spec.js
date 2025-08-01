const { test, expect } = require('../support/test-setup');

test.describe('Learn Page', () => {
  test('should display confetti on page load', async ({ page }) => {
    // Navigate to the learn page
    await page.goto('/learn');

    // Verify the page loaded correctly
    await expect(page.getByText("You've Got Bitcoin!")).toBeVisible();

    // Check that the confetti controller is attached
    const confettiElement = page.locator('[data-controller="confetti"]');
    await expect(confettiElement).toBeVisible();

    // Verify the three option cards are visible
    await expect(page.getByText('I already have Bitcoin')).toBeVisible();
    await expect(page.getByText("I'm a Newcoiner (beginner)")).toBeVisible();
    await expect(page.getByText('Just Curious')).toBeVisible();

    // Verify the recommended badge
    await expect(page.getByText('RECOMMENDED')).toBeVisible();
  });

  test('should navigate to correct pages when clicking options', async ({ page }) => {
    await page.goto('/learn');

    // Test "I already have Bitcoin" link
    await page.getByText('I already have Bitcoin').click();
    await expect(page).toHaveURL(/\/hong_baos/);

    // Go back and test "I'm a Newcoiner" link
    await page.goto('/learn');
    await page.getByText("I'm a Newcoiner (beginner)").click();
    await expect(page.locator('body')).toContainText("What is Bitcoin?")

    // Go back and test "Just Curious" link
    await page.goto('/learn');
    await page.getByText('Just Curious').click();
    await expect(page.locator('body')).toContainText('Learn')
  });
});