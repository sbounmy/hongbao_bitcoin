import { test, expect } from '../support/test-setup';
import { forceLogin } from '../support/on-rails';

async function drag(page, dragHandle, { targetElement, dx, dy }, moveOptions = { steps: 5 }) {
  const targetBox = await targetElement.boundingBox();
  if (!targetBox) {
    throw new Error('Target element for drag not found or not visible.');
  }
  await dragHandle.hover();
  await page.mouse.down();
  await page.mouse.move(targetBox.x + dx, targetBox.y + dy, moveOptions);
  await page.mouse.up();
}


test.describe('Visual Editor', () => {
  test.beforeEach(async ({ page }) => {
    await forceLogin(page, { email: 'admin@example.com',
      redirect_to: '/admin/papers/1/edit'
    });
    await expect(page.locator('.visual-editor-container')).toBeVisible();
  });

  test('switches between front and back views', async ({ page }) => {
    const frontTab = page.getByRole('button', { name: 'Front' });
    const backTab = page.getByRole('button', { name: 'Back' });
    const frontElement = page.locator('[data-element-type="public_address_qrcode"][data-visual-editor-target="element"]');
    const backElement = page.locator('[data-element-type="private_key_qrcode"][data-visual-editor-target="element"]');

    // Starts on Front
    await expect(frontTab).toHaveClass("btn btn-sm btn-active");
    await expect(backTab).not.toHaveClass("btn btn-sm btn-active");
    await expect(frontElement).toBeVisible();
    await expect(backElement).toBeHidden();

    // Switch to Back
    await backTab.click();
    // Wait for a visual side-effect to ensure the UI has updated
    await expect(backElement).toBeVisible();
    // Check for the positive class change first for stability
    await expect(backTab).toHaveClass("btn btn-sm tab-active");
    await expect(frontTab).not.toHaveClass("btn btn-sm tab-active");
    await expect(frontElement).toBeHidden();

    // Switch back to Front
    await frontTab.click();
    await expect(frontElement).toBeVisible();
    await expect(frontTab).toHaveClass("btn btn-sm btn-active tab-active");
  });

  test('can drag elements and updates form fields', async ({ page }) => {
    const element = page.locator('[data-element-type="public_address_qrcode"][data-visual-editor-target="element"]');
    const xInput = page.locator('input[name="paper[elements][public_address_qrcode][x]"]');
    const yInput = page.locator('input[name="paper[elements][public_address_qrcode][y]"]');

    const initialX = await xInput.inputValue();
    const initialY = await yInput.inputValue();

    await drag(page, element, { targetElement: element, dx: 60, dy: 40 });

    await expect(xInput).not.toHaveValue(initialX);
    await expect(yInput).not.toHaveValue(initialY);
  });

  test('resets only visible elements when reset button is clicked', async ({ page }) => {
    const element = page.locator('[data-element-type="public_address_qrcode"][data-visual-editor-target="element"]');
    const xInput = page.locator('input[name="paper[elements][public_address_qrcode][x]"]');
    const yInput = page.locator('input[name="paper[elements][public_address_qrcode][y]"]');
    const resetButton = page.getByRole('button', { name: 'Reset' });

    // Move element
    await drag(page, element, { targetElement: element, dx: 60, dy: 40 });

    await expect(xInput).not.toHaveValue("30");
    await expect(yInput).not.toHaveValue("30");

    await resetButton.click();

    await expect(xInput).toHaveValue("30");
    await expect(yInput).toHaveValue("30");
  });

  test.describe('Properties Panel', () => {
    test('opens on element click and shows correct controls for QR Code', async ({ page }) => {
      const element = page.locator('[data-element-type="public_address_qrcode"][data-visual-editor-target="element"]');
      const panel = page.locator('[data-visual-editor-target="propertiesPanel"]');

      await expect(panel).toBeHidden();
      await element.click();
      await expect(panel).toBeVisible();

      await expect(panel.locator('[data-visual-editor-target="panelTitle"]')).toHaveText('Public Address Qrcode');
      await expect(panel.locator('[data-visual-editor-target="panelSizeContainer"]')).toBeVisible();
      await expect(panel.locator('[data-visual-editor-target="panelColorContainer"]')).toBeHidden();
      await expect(panel.locator('[data-visual-editor-target="panelMaxWidthContainer"]')).toBeHidden();
      await expect(panel.locator('[data-visual-editor-target="panelPreviewTextContainer"]')).toBeHidden();
    });

    test('can be dragged', async ({ page }) => {
        const panel = page.locator('[data-visual-editor-target="propertiesPanel"]');
        const handle = panel.locator('[data-visual-editor-target="panelHandle"]');
        await page.locator('[data-element-type="public_address_qrcode"][data-visual-editor-target="element"]').click();
        await expect(panel).toBeVisible();

        const initialBox = await panel.boundingBox();
        await handle.hover();
        await page.mouse.down();
        await page.mouse.move(initialBox.x - 50, initialBox.y - 50, { steps: 10 });
        await page.mouse.up();

        const finalBox = await panel.boundingBox();
        expect(finalBox.x).not.toEqual(initialBox.x);
        expect(finalBox.y).not.toEqual(initialBox.y);
    });

    test('updates element preview text from panel', async ({ page }) => {
      const element = page.locator('[data-element-type="public_address_text"][data-visual-editor-target="element"]');
      const panel = page.locator('[data-visual-editor-target="propertiesPanel"]');

      await element.click();
      const panelPreviewInput = panel.locator('[data-visual-editor-target="panelPreviewTextInput"]');

      await panelPreviewInput.fill('Hello Playwright');
      await expect(element.locator('p')).toHaveText('Hello Playwright');
    });
  });

  test.describe('Resizing', () => {
    test('does not allow vertical resizing for text elements', async ({ page }) => {
      const element = page.locator('[data-element-type="public_address_text"][data-visual-editor-target="element"]');
      const sizeInput = page.locator('input[name="paper[elements][public_address_text][size]"]');
      const initialSize = await sizeInput.inputValue();
      const initialBox = await element.boundingBox();

      const resizeHandle = { x: initialBox.x + initialBox.width / 2, y: initialBox.y + initialBox.height - 2 };

      await page.mouse.move(resizeHandle.x, resizeHandle.y);
      await page.mouse.down();
      await page.mouse.move(resizeHandle.x, resizeHandle.y + 50, { steps: 5 });
      await page.mouse.up();

      await expect(sizeInput).toHaveValue(initialSize);
    });
  });
});