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
    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (const day of dayHeaders) {
      await expect(page.getByText(day, { exact: true }).first()).toBeVisible();
    }
    
    // Check current month is displayed in the calendar header
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    await expect(page.locator('.lg\\:col-span-4').getByText(currentMonth)).toBeVisible();
  });

  test('shows events for the current month', async ({ page }) => {
    await page.goto('/calendar');
    
    // Check that events section exists
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    await expect(page.getByText(`Events in ${currentMonth}`)).toBeVisible();
    
    // If there are events (using fixtures), they should be displayed
    const eventCards = page.locator('.card-side');
    const count = await eventCards.count();
    
    if (count > 0) {
      // Check first event has required elements
      const firstEvent = eventCards.first();
      await expect(firstEvent).toBeVisible();
      
      // Event should have date display
      await expect(firstEvent.locator('.text-2xl.font-bold')).toBeVisible();
      
      // Event should have a name
      await expect(firstEvent.locator('.font-semibold')).toBeVisible();
    }
  });

  test('navigates between months', async ({ page }) => {
    // Start with a known date to avoid edge cases
    await page.goto('/calendar?date=2024-06-15');
    
    // Check we're on June 2024
    await expect(page.locator('.lg\\:col-span-4 h2')).toContainText('June 2024');
    
    // Navigate to previous month
    const prevButton = page.locator('.lg\\:col-span-4 .btn-circle').first();
    await prevButton.click();
    
    // Wait for URL to change and content to load
    await expect(page).toHaveURL(/date=2024-05/);
    await expect(page.locator('.lg\\:col-span-4 h2')).toContainText('May 2024');
    
    // Navigate forward to June
    const nextButton = page.locator('.lg\\:col-span-4 .btn-circle').last();
    await nextButton.click();
    
    // Wait for URL to change back to June
    await expect(page).toHaveURL(/date=2024-06/);
    await expect(page.locator('.lg\\:col-span-4 h2')).toContainText('June 2024');
    
    // Navigate forward again to July
    await nextButton.click();
    
    // Wait for URL to change to July
    await expect(page).toHaveURL(/date=2024-07/);
    await expect(page.locator('.lg\\:col-span-4 h2')).toContainText('July 2024');
  });

  test('highlights today\'s date', async ({ page }) => {
    await page.goto('/calendar');
    
    // Find the parent div that contains today's gradient background
    const todayParent = page.locator('.aspect-square').filter({ 
      has: page.locator('.bg-gradient-to-br.from-orange-500.to-orange-600') 
    });
    
    // Today's date should be visible with white text
    const todayElement = todayParent.locator('.text-white.font-bold');
    await expect(todayElement).toBeVisible();
    
    // Check it contains today's date
    const today = new Date().getDate().toString();
    await expect(todayElement).toContainText(today);
  });

  test('shows no events message for empty months', async ({ page }) => {
    // Navigate to a future month that should have no events
    await page.goto('/calendar?date=2099-12-01');
    
    await expect(page.getByText('No Bitcoin milestones this month')).toBeVisible();
  });

  test('displays event details in list format', async ({ page }) => {
    // Navigate to a month with known events (using fixtures)
    await page.goto('/calendar?date=2009-01-01');
    
    // Check for genesis block event (from fixtures)
    const genesisEvent = page.locator('.card-side', { hasText: 'Genesis Block' });
    const eventCount = await genesisEvent.count();
    
    if (eventCount > 0) {
      // Check event structure
      await expect(genesisEvent).toBeVisible();
      
      // Should have date display
      await expect(genesisEvent.locator('.text-2xl')).toBeVisible();
      
      // Should have month abbreviation
      await expect(genesisEvent.locator('.uppercase')).toBeVisible();
      
      // Should show age if applicable
      const ageText = genesisEvent.locator('.badge', { hasText: 'years old' });
      if (await ageText.count() > 0) {
        await expect(ageText).toBeVisible();
      }
    }
  });

  test('shows event thumbnails and placeholders', async ({ page }) => {
    await page.goto('/calendar');
    
    const eventCards = page.locator('.card-side');
    const count = await eventCards.count();
    
    if (count > 0) {
      // Check for image or placeholder
      const firstEvent = eventCards.first();
      
      // Should have either an image or SVG placeholder
      const hasImage = await firstEvent.locator('figure img').count() > 0;
      const hasPlaceholder = await firstEvent.locator('.w-24.h-24 svg').count() > 0;
      
      expect(hasImage || hasPlaceholder).toBeTruthy();
    }
  });

  test('navigates to event detail page', async ({ page }) => {
    await page.goto('/calendar');
    
    const eventCards = page.locator('.card-side');
    const count = await eventCards.count();
    
    if (count > 0) {
      // Click the arrow button on the first event
      const arrowButton = eventCards.first().locator('.btn-ghost.btn-circle');
      await arrowButton.click();
      
      // Should navigate to input page
      await expect(page).toHaveURL(/\/inputs\/\d+/);
    }
  });

  test('shows calendar legend', async ({ page }) => {
    await page.goto('/calendar');
    
    // Check legend items
    await expect(page.getByText('Today')).toBeVisible();
    await expect(page.getByText('Bitcoin Event')).toBeVisible();
    
    // Check legend indicators exist - updated for new orange theme
    await expect(page.locator('.w-4.h-4.bg-gradient-to-br')).toBeVisible();
    await expect(page.locator('.w-4.h-4.bg-orange-500\\/10')).toBeVisible();
  });

  test('preserves date when navigating', async ({ page }) => {
    // Start at a specific date
    await page.goto('/calendar?date=2024-06-15');
    
    // Verify we're on June 2024 in calendar header
    await expect(page.locator('.lg\\:col-span-4').getByText('June 2024')).toBeVisible();
    
    // Navigate to previous month
    await page.locator('.btn-circle').first().click();
    
    // Should be on May 2024 in calendar header
    await expect(page.locator('.lg\\:col-span-4').getByText('May 2024')).toBeVisible();
    
    // Check URL has updated
    await expect(page).toHaveURL(/date=2024-05/);
  });
});