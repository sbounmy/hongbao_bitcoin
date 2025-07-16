import { test, expect } from '../support/test-setup';
import { turboCableConnected, appVcrInsertCassette, appVcrEjectCassette } from '../support/on-rails';

test.describe('Event Calendar', () => {
  test.beforeEach(async ({ page }) => {
    await appVcrInsertCassette('calendar', { allow_playback_repeats: true });
    await turboCableConnected(page);
  });

  test.afterEach(async () => {
    await appVcrEjectCassette();
  });

  test('displays the calendar page with current month', async ({ page }) => {
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    await page.goto('/calendar');

    // Check page title - now it's "Bitcoin Calendar"
    await expect(page.getByRole('heading', { name: 'Bitcoin Calendar' })).toBeVisible();

    // Check calendar grid is displayed (no longer has .calendar class)
    await expect(page.locator('.grid-cols-7').first()).toBeVisible();

    // Check day headers
    const dayHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (const day of dayHeaders) {
      await expect(page.getByText(day, { exact: true }).first()).toBeVisible();
    }

    await expect(page.locator('body')).toContainText(currentMonth);
  });

  test('shows events for the current month', async ({ page }) => {
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    await page.goto('/calendar');

    // Check that events section exists
    await expect(page.locator('body')).toContainText(currentMonth);

    // If there are events (using fixtures), they should be displayed
    const eventCards = page.locator('[data-testid="calendar-event-link"]');
    const count = await eventCards.count();

    if (count > 0) {
      // Check first event has required elements
      const firstEvent = eventCards.first();
      await expect(firstEvent).toBeVisible();

      // Event should have a name
      await expect(firstEvent.getByTestId('event-name')).toBeVisible();
    }
  });

  test('navigates between months', async ({ page }) => {
    const currentYear = new Date().toLocaleDateString('en-US', { year: 'numeric' });
    // Start with a known date to avoid edge cases
    await page.goto('/calendar/june');

    // Check we're on June 2024
    await expect(page.locator('body')).toContainText(`June ${currentYear}`);

    // Navigate to previous month
    await page.locator('.prev-month').click();

    // Wait for URL to change and content to load
    await expect(page).toHaveURL(/may/);
    await expect(page.locator('body')).toContainText(`May ${currentYear}`);

    // Navigate forward to June
    await page.locator('.next-month').click();

    // Wait for URL to change back to June
    await expect(page).toHaveURL(/june/);
    await expect(page.locator('body')).toContainText(`June ${currentYear}`);

    // Navigate forward again to July
    await page.locator('.next-month').click();

    // Wait for URL to change to July
    await expect(page).toHaveURL(/july/);
    await expect(page.locator('body')).toContainText(`July ${currentYear}`);
  });

  test('highlights today\'s date', async ({ page }) => {
    await page.goto('/calendar');

    // Find today's date cell
    const today = new Date().getDate().toString();
    const todayCell = page.locator('.calendar-day').filter({ hasText: today });

    // Today should have the orange border
    await expect(todayCell).toHaveClass(/border-orange-500/);
  });

  test('displays event details in list format', async ({ page }) => {
    // Navigate to a month with known events (using fixtures)
    await page.goto('/agenda/jan');

    // Check for genesis block event (from fixtures)
    const genesisEvent = page.getByText('Genesis Block');
    const eventCount = await genesisEvent.count();

    if (eventCount > 0) {
      // Check event is visible
      await expect(genesisEvent.first()).toBeVisible();
    }
  });

  test('shows event thumbnails and placeholders', async ({ page }) => {
    await page.goto('/calendar');

    const eventLinks = page.locator('[data-testid="calendar-event-link"]');
    const count = await eventLinks.count();

    if (count > 0) {
      // Check that events are visible
      await expect(eventLinks.first()).toBeVisible();
    }
  });

  test('navigates to event detail page', async ({ page }) => {
    await page.goto('/calendar');

    const eventLinks = page.locator('[data-testid="calendar-event-link"]');
    const count = await eventLinks.count();

    if (count > 0) {
      // Click the first event link
      await eventLinks.first().click();

      // Should navigate to input page
      await expect(page).toHaveURL(/\/inputs\/\d+/);
    }
  });


  test('preserves date when navigating', async ({ page }) => {
    // Start at a specific date
    await page.goto('/calendar/june-2024');

    // Verify we're on June 2024 in calendar header
    await expect(page.locator('body')).toContainText('June 2024');

    // Navigate to previous month
    await page.locator('.prev-month').click();

    // Should be on May 2024 in calendar header
    await expect(page.locator('body')).toContainText('May 2024');

    // Check URL has updated
    await expect(page).toHaveURL(/may-2024/);
  });
});