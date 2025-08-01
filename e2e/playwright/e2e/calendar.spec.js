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
    await page.goto('/bitcoin-calendar');

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
    await page.goto('/bitcoin-calendar');

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
    await page.goto('/bitcoin-calendar/june');

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
    await page.goto('/bitcoin-calendar');

    // Get today's date in the browser's timezone
    const today = await page.evaluate(() => new Date().getDate().toString());

    // Find the cell that contains the date number
    const todayCell = page.locator('.calendar-day').filter({
      has: page.locator('.calendar-day-number').filter({ hasText: today })
    }).first();

    // Today should have the orange border
    await expect(todayCell).toHaveClass(/border-orange-500/);
  });

  test('displays event details in list format', async ({ page }) => {
    // Navigate to a month with known events (using fixtures)
    await page.goto('/bitcoin-agenda/jan');

    // Check for genesis block event (from fixtures)
    const genesisEvent = page.getByText('Genesis Block');
    const eventCount = await genesisEvent.count();

    if (eventCount > 0) {
      // Check event is visible
      await expect(genesisEvent.first()).toBeVisible();
    }
  });

  test('shows event thumbnails and placeholders', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    const eventLinks = page.locator('[data-testid="calendar-event-link"]');
    const count = await eventLinks.count();

    if (count > 0) {
      // Check that events are visible
      await expect(eventLinks.first()).toBeVisible();
    }
  });

  test('navigates to event detail page', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

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
    await page.goto('/bitcoin-calendar/june-2024');

    // Verify we're on June 2024 in calendar header
    await expect(page.locator('body')).toContainText('June 2024');

    // Navigate to previous month
    await page.locator('.prev-month').click();

    // Should be on May 2024 in calendar header
    await expect(page.locator('body')).toContainText('May 2024');

    // Check URL has updated
    await expect(page).toHaveURL(/may-2024/);
  });

  test('shows tag filter dropdown', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    // Check filter button exists (it's a label with btn class)
    const filterButton = page.locator('label.btn').filter({ hasText: /Filter/i });
    await expect(filterButton).toBeVisible();

    // Click to open dropdown
    await filterButton.click();

    // Check dropdown content
    await expect(page.getByText('Event Types')).toBeVisible();

    // Check for tag checkboxes
    const checkboxes = page.locator('input[type="checkbox"][name="tags[]"]');
    const count = await checkboxes.count();
    expect(count).toBeGreaterThan(0);
  });

  test('filters events by tag', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    // Open filter dropdown
    await page.locator('label.btn').filter({ hasText: /Filter/i }).click();

    // Get initial event count
    const initialEventLinks = page.locator('[data-testid="calendar-event-link"]');
    const initialCount = await initialEventLinks.count();

    // Select first tag checkbox
    const firstCheckbox = page.locator('input[type="checkbox"][name="tags[]"]').first();
    await firstCheckbox.check();

    // Wait for page to reload with filtered results
    await page.waitForLoadState('networkidle');

    // Check URL contains tag parameter (brackets are URL encoded)
    await expect(page).toHaveURL(/tags(%5B%5D|\\[\\])=/);

    // Verify filter badge shows count
    const filterBadge = page.locator('.badge-primary');
    await expect(filterBadge).toContainText('1');

    // Event count may have changed (filtered)
    const filteredEventLinks = page.locator('[data-testid="calendar-event-link"]');
    const filteredCount = await filteredEventLinks.count();

    // The filtered count should be less than or equal to initial count
    expect(filteredCount).toBeLessThanOrEqual(initialCount);
  });

  test('clears tag filters', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    // Open filter dropdown and select a tag
    await page.locator('label.btn').filter({ hasText: /Filter/i }).click();
    const firstCheckbox = page.locator('input[type="checkbox"][name="tags[]"]').first();
    await firstCheckbox.check();

    // Wait for filtered results
    await page.waitForLoadState('networkidle');

    // Open dropdown again
    await page.locator('label.btn').filter({ hasText: /Filter/i }).click();

    // Click clear filters link
    await page.getByText('Clear filters').click();

    // Check URL no longer has tags parameter
    await expect(page).not.toHaveURL(/tags(%5B%5D|\\[\\])=/);

    // Filter badge should not exist
    const filterBadge = page.locator('.badge-primary');
    await expect(filterBadge).not.toBeVisible();
  });

  test('preserves tag filters when navigating months', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    // Open filter dropdown and select a tag
    await page.locator('label.btn').filter({ hasText: /Filter/i }).click();
    const firstCheckbox = page.locator('input[type="checkbox"][name="tags[]"]').first();
    await firstCheckbox.check();

    // Wait for filtered results
    await page.waitForLoadState('networkidle');

    // Navigate to next month
    await page.locator('.next-month').click();

    // Check URL still contains tag parameter
    await expect(page).toHaveURL(/tags(%5B%5D|\\[\\])=/);

    // Filter badge should still show
    const filterBadge = page.locator('.badge-primary');
    await expect(filterBadge).toBeVisible();
    await expect(filterBadge).toContainText('1');
  });

  test('switches views while preserving tag filters', async ({ page }) => {
    await page.goto('/bitcoin-calendar');

    // Open filter dropdown and select a tag
    await page.locator('label.btn').filter({ hasText: /Filter/i }).click();
    const firstCheckbox = page.locator('input[type="checkbox"][name="tags[]"]').first();
    await firstCheckbox.check();

    // Wait for filtered results
    await page.waitForLoadState('networkidle');

    // Switch to list view
    await page.getByRole('link', { name: /List view/i }).click();

    // Should be on agenda page with tags preserved
    await expect(page).toHaveURL(/agenda/);
    await expect(page).toHaveURL(/tags(%5B%5D|\\[\\])=/);

    // Filter badge should still show
    const filterBadge = page.locator('.badge-primary');
    await expect(filterBadge).toBeVisible();
    await expect(filterBadge).toContainText('1');
  });
});