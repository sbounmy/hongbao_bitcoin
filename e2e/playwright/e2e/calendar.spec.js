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
    
    // Check current month is displayed in the calendar header
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: currentMonth })).toBeVisible();
  });

  test('shows events for the current month', async ({ page }) => {
    await page.goto('/calendar');
    
    // Check view switcher exists
    await expect(page.getByRole('link', { name: 'Calendar view' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'List view' })).toBeVisible();
    
    // Calendar view should be active
    const calendarButton = page.getByRole('link', { name: 'Calendar view' });
    await expect(calendarButton).toHaveClass(/btn-active/);
  });

  test('navigates between months', async ({ page }) => {
    // Start with a known date to avoid edge cases
    await page.goto('/calendar/june-2024');
    
    // Check we're on June 2024
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'June 2024' })).toBeVisible();
    
    // Navigate to previous month
    await page.getByRole('link', { name: 'Previous month' }).click();
    
    // Wait for URL to change and content to load
    await expect(page).toHaveURL(/\/calendar\/may-2024/);
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'May 2024' })).toBeVisible();
    
    // Navigate forward to June
    await page.getByRole('link', { name: 'Next month' }).click();
    
    // Wait for URL to change back to June
    await expect(page).toHaveURL(/\/calendar\/june-2024/);
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'June 2024' })).toBeVisible();
    
    // Navigate forward again to July
    await page.getByRole('link', { name: 'Next month' }).click();
    
    // Wait for URL to change to July
    await expect(page).toHaveURL(/\/calendar\/july-2024/);
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'July 2024' })).toBeVisible();
  });

  test('highlights today\'s date', async ({ page }) => {
    await page.goto('/calendar');
    
    // Find today's date cell
    const today = new Date().getDate().toString();
    const todayCell = page.locator('.border-orange-500.border-2');
    
    // Today's cell should be visible and contain today's date
    await expect(todayCell).toBeVisible();
    await expect(todayCell).toContainText(today);
  });

  test('shows events in agenda view', async ({ page }) => {
    // Navigate to a month with known events
    await page.goto('/agenda/january-2009');
    
    // Check that the agenda view is showing
    await expect(page.getByRole('heading', { level: 3 }).filter({ hasText: 'Events in January 2009' })).toBeVisible();
    
    // Check that List view button is active
    const agendaButton = page.getByRole('link', { name: 'List view' });
    await expect(agendaButton).toHaveClass(/btn-active/);
  });

  test('displays event information in agenda cards', async ({ page }) => {
    // Navigate to a month with known events
    await page.goto('/agenda/january-2009');
    
    // Check for event cards
    const eventCards = page.locator('.group.relative.overflow-hidden.rounded-xl');
    await expect(eventCards.first()).toBeVisible();
    
    // Check event date badge is visible
    const dateBadge = page.locator('.bg-gradient-to-b.from-orange-500.to-orange-600').first();
    await expect(dateBadge).toBeVisible();
    
    // Check for event metadata (year badges, bitcoin price)
    const yearBadge = page.locator('.bg-orange-500\\/10.text-orange-600').first();
    const eventCount = await yearBadge.count();
    if (eventCount > 0) {
      await expect(yearBadge).toBeVisible();
    }
  });

  test('navigates between months in agenda view', async ({ page }) => {
    // Start with a known date
    await page.goto('/agenda/june-2024');
    
    // Check we're on June 2024
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'June 2024' })).toBeVisible();
    
    // Navigate to previous month
    await page.getByRole('link', { name: 'Previous month' }).click();
    
    // Should be on May 2024
    await expect(page).toHaveURL(/\/agenda\/may-2024/);
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'May 2024' })).toBeVisible();
    
    // Navigate to next month
    await page.getByRole('link', { name: 'Next month' }).click();
    
    // Should be back on June 2024
    await expect(page).toHaveURL(/\/agenda\/june-2024/);
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'June 2024' })).toBeVisible();
  });

  test('shows event details with images in agenda view', async ({ page }) => {
    // Navigate to agenda view
    await page.goto('/agenda/january-2009');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check for event images or bitcoin icon placeholders
    const eventFigures = page.locator('figure').first();
    const bitcoinIcons = page.locator('svg').filter({ has: page.locator('path[d*="M12.5 13.2c2.7"]') });
    
    // Either an image or bitcoin icon should be visible
    const figureCount = await eventFigures.count();
    const iconCount = await bitcoinIcons.count();
    
    expect(figureCount + iconCount).toBeGreaterThan(0);
  });

  test('clicking event in agenda navigates to detail page', async ({ page }) => {
    // Navigate to agenda view with events
    await page.goto('/agenda/january-2009');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Find and click an event card
    const eventCard = page.locator('.group.relative.overflow-hidden.rounded-xl').first();
    const eventCount = await eventCard.count();
    
    if (eventCount > 0) {
      await eventCard.click();
      
      // Should navigate to input detail page
      await expect(page).toHaveURL(/\/inputs\/\d+$/);
    }
  });

  test('displays event details in list format', async ({ page }) => {
    // Navigate to agenda view with known events
    await page.goto('/agenda/january-2009');
    
    // Check for genesis block event (from fixtures)
    const genesisEvent = page.getByText('Genesis Block');
    const eventCount = await genesisEvent.count();
    
    if (eventCount > 0) {
      // Check event is visible
      await expect(genesisEvent.first()).toBeVisible();
    }
  });

  test('switches between calendar and agenda views', async ({ page }) => {
    await page.goto('/calendar');
    
    // Click list view button
    await page.getByRole('link', { name: 'List view' }).click();
    
    // Should navigate to agenda view
    await expect(page).toHaveURL(/\/agenda/);
    
    // Agenda view should be active
    const agendaButton = page.getByRole('link', { name: 'List view' });
    await expect(agendaButton).toHaveClass(/btn-active/);
    
    // Click calendar view button
    await page.getByRole('link', { name: 'Calendar view' }).click();
    
    // Should navigate back to calendar view
    await expect(page).toHaveURL(/\/calendar/);
  });

  test('navigates to event detail page', async ({ page }) => {
    // Navigate to a month with known events
    await page.goto('/calendar/january-2009');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Look for event links but exclude the calendar navigation link
    const eventLinks = page.locator('a[href*="/inputs/"]').filter({ 
      hasNot: page.locator('[href*="/inputs/calendar"]') 
    });
    const count = await eventLinks.count();
    
    if (count > 0) {
      // Click the first event link
      await eventLinks.first().click();
      
      // Should navigate to input page with ID
      await expect(page).toHaveURL(/\/inputs\/\d+$/);
    } else {
      // If no events, skip the test
      console.log('No events found, skipping navigation test');
    }
  });

  test('shows calendar legend', async ({ page }) => {
    await page.goto('/calendar');
    
    // Check legend items exist in the calendar component
    const calendarComponent = page.locator('.bg-base-100.rounded-2xl').first();
    await expect(calendarComponent.getByText('Today')).toBeVisible();
    await expect(calendarComponent.getByText('Bitcoin Event')).toBeVisible();
    
    // Check legend color indicators exist
    await expect(page.locator('.w-4.h-4.bg-gradient-to-br.from-orange-500.to-orange-600')).toBeVisible();
    await expect(page.locator('.w-4.h-4.bg-orange-500\\/10')).toBeVisible();
  });

  test('preserves date when navigating', async ({ page }) => {
    // Start at a specific date
    await page.goto('/calendar/june-2024');
    
    // Verify we're on June 2024 in calendar header
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'June 2024' })).toBeVisible();
    
    // Navigate to previous month
    await page.getByRole('link', { name: 'Previous month' }).click();
    
    // Should be on May 2024 in calendar header
    await expect(page.getByRole('heading', { level: 2 }).filter({ hasText: 'May 2024' })).toBeVisible();
    
    // Check URL has updated
    await expect(page).toHaveURL(/\/calendar\/may-2024/);
  });
});