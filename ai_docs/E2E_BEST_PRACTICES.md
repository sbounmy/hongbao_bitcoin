# E2E Testing Best Practices for Hongbao

This document outlines the conventions and best practices for writing E2E tests in the Hongbao project.

## Test Structure

### Imports
```javascript
import { test, expect } from '../support/test-setup';
import { app, appScenario, forceLogin, appVcrInsertCassette, appVcrEjectCassette, turboCableConnected } from '../support/on-rails';
```

### File Naming
- Use descriptive names: `feature_name.spec.js` (e.g., `authentication.spec.js`, `paper_likes.spec.js`)
- Place test files in `e2e/playwright/e2e/` directory

## Data Management

### Use Fixtures Over Factories
- **Preferred**: Use pre-seeded Rails fixtures loaded via `app('activerecord_fixtures')`
- **Why**: Fixtures are faster and more predictable than dynamically creating data
- **Available Users**: 
  - `satoshi@example.com` (password: `03/01/2009`)
  - Check Rails fixtures for other available test data

### VCR Cassettes for External APIs
```javascript
test.beforeEach(async ({ page }) => {
  await appVcrInsertCassette('feature_name', { allow_playback_repeats: true });
});

test.afterEach(async ({ page }) => {
  await appVcrEjectCassette();
});
```

## Authentication

### Force Login (Preferred)
```javascript
await forceLogin(page, {
  email: 'satoshi@example.com',
  redirect_to: '/target/path'
});
```

### Manual Login (When Testing Auth Flow)
```javascript
await page.getByPlaceholder('Email address').fill('satoshi@example.com');
await page.getByRole('button', { name: 'Continue' }).click();
await page.getByPlaceholder('Password').fill('03/01/2009');
await page.getByRole('button', { name: 'Sign in' }).click();
```

## Turbo and Real-time Features

### Wait for Turbo Cable Connection
```javascript
await turboCableConnected(page);
```

### Testing Turbo Stream Updates
```javascript
// Trigger action
await page.getByRole('button', { name: 'Like' }).click();

// Wait for DOM updates
await expect(page.locator('#likes_count')).toHaveText('1');
```

### Process Background Jobs
```javascript
await app('perform_jobs'); // Processes queued jobs synchronously
```

## Locator Strategies

### Priority Order
1. **Semantic locators** (preferred):
   ```javascript
   page.getByRole('button', { name: 'Submit' })
   page.getByText('Welcome')
   page.getByPlaceholder('Email')
   ```

2. **CSS selectors** (when semantic not available):
   ```javascript
   page.locator('.papers-item-component')
   page.locator('#like_button_paper_1')
   ```

3. **data-testid** (use sparingly):
   ```javascript
   page.locator('[data-testid="special-element"]')
   ```

## Assertions

### Common Patterns
```javascript
// Visibility
await expect(element).toBeVisible();
await expect(element).toBeHidden();

// Content
await expect(page.locator('body')).toContainText('Expected text');
await expect(element).toHaveText('Exact text');

// Count
await expect(page.locator('.item')).toHaveCount(3);

// Attributes/Classes
await expect(element).toHaveAttribute('href', '/path');
await expect(element).toHaveClass(/active/);

// State
await expect(input).toBeChecked();
await expect(button).toBeDisabled();
```

## Timeouts

### Set Appropriate Timeouts for CI
```javascript
test.setTimeout(40_000); // 40 seconds for CI environments
```

## Test Organization

### Use describe blocks for feature grouping
```javascript
test.describe('Feature Name', () => {
  test.describe('when authenticated', () => {
    test('specific behavior', async ({ page }) => {
      // test implementation
    });
  });
  
  test.describe('when unauthenticated', () => {
    test('different behavior', async ({ page }) => {
      // test implementation
    });
  });
});
```

## Common Helpers

### Available Helper Functions
- `forceLogin(page, options)` - Quick authentication
- `turboCableConnected(page)` - Wait for WebSocket connection
- `fillCheckout(page, options)` - Fill Stripe checkout forms
- `app(command)` - Execute Rails commands
- `appScenario(name)` - Load specific test scenarios
- `appVcrInsertCassette(name, options)` - Start VCR recording
- `appVcrEjectCassette()` - Stop VCR recording

## Anti-patterns to Avoid

1. **Don't use appFactories** - Use fixtures instead
2. **Don't create complex Page Objects** - Keep tests simple and direct
3. **Don't use hard-coded waits** - Use Playwright's auto-waiting with proper assertions
4. **Don't test implementation details** - Focus on user-visible behavior
5. **Don't share state between tests** - Each test should be independent

## Example Test

```javascript
import { test, expect } from '../support/test-setup';
import { forceLogin, turboCableConnected } from '../support/on-rails';

test.describe('Paper Likes', () => {
  test('user can like and unlike papers', async ({ page }) => {
    await forceLogin(page, {
      email: 'satoshi@example.com',
      redirect_to: '/papers/explore'
    });
    
    await turboCableConnected(page);
    
    const likeButton = page.locator('.papers-item-component').first()
      .locator('button[id^="like_button_paper_"]');
    
    // Like the paper
    await likeButton.click();
    await expect(likeButton.locator('svg')).toHaveClass(/text-red-500/);
    
    // Unlike the paper
    await likeButton.click();
    await expect(likeButton.locator('svg')).not.toHaveClass(/text-red-500/);
  });
});
```