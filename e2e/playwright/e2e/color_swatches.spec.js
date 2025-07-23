import { test, expect } from '../support/test-setup';

test.describe('Color Selection', () => {
  // test.beforeEach(async ({ page }) => {
  //   await appVcrInsertCassette('stripe_products', { allow_playback_repeats: true });
  // });

  // test.afterEach(async () => {
  //   await appVcrEjectCassette();
  // });

  test('updates URL when color is selected', async ({ page }) => {
    await page.goto('/#pricing');
    
    await page.getByText('Mini Pack').click();
    await expect(page).toHaveURL(/pack=mini/);
    
    const colorButtons = page.locator('label[aria-label^="Select "][aria-label$=" color"]');
    const firstColorButton = colorButtons.first();
    await expect(firstColorButton).toBeVisible();
    
    const ariaLabel = await firstColorButton.getAttribute('aria-label');
    const color = ariaLabel?.match(/Select (\w+) color/)?.[1];
    expect(color).toBeTruthy();
    
    await firstColorButton.click();
    await expect(page).toHaveURL(new RegExp(`color=${color}`));
  });

  test('preserves color in URL when changing packs', async ({ page }) => {
    await page.goto('/#pricing');
    
    await page.getByText('Mini Pack').click();
    await expect(page).toHaveURL(/pack=mini/);
    
    const colorButtons = page.locator('label[aria-label^="Select "][aria-label$=" color"]');
    const firstColorButton = colorButtons.first();
    const ariaLabel = await firstColorButton.getAttribute('aria-label');
    const color = ariaLabel?.match(/Select (\w+) color/)?.[1];
    expect(color).toBeTruthy();
    
    await firstColorButton.click();
    await expect(page).toHaveURL(new RegExp(`color=${color}`));
    
    await page.getByText('Family Pack').click();
    
    await expect(page).toHaveURL(/pack=family/);
    await expect(page).toHaveURL(new RegExp(`color=${color}`));
  });

  test.skip('can switch between multiple colors', async ({ page }) => { // currently skipping because we only have one colour
    await page.goto('/?pack=mini#pricing');
    
    const colorButtons = page.locator('label[aria-label^="Select "][aria-label$=" color"]');
    const firstColorButton = colorButtons.first();
    const secondColorButton = colorButtons.nth(1);
    
    const firstAriaLabel = await firstColorButton.getAttribute('aria-label');
    const firstColor = firstAriaLabel?.match(/Select (\w+) color/)?.[1];
    
    const secondAriaLabel = await secondColorButton.getAttribute('aria-label');
    const secondColor = secondAriaLabel?.match(/Select (\w+) color/)?.[1];
    
    expect(firstColor).toBeTruthy();
    expect(secondColor).toBeTruthy();
    expect(secondColor).not.toBe(firstColor);
    
    await firstColorButton.click();
    await expect(page).toHaveURL(new RegExp(`color=${firstColor}`));
    
    await secondColorButton.click();
    await expect(page).toHaveURL(new RegExp(`color=${secondColor}`));
    await expect(page).not.toHaveURL(new RegExp(`color=${firstColor}`));
  });
});