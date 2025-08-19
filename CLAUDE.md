# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hong₿ao is a Ruby on Rails 8 application for generating Bitcoin paper wallets in red envelope format. It uses Hotwire (Turbo + Stimulus) for frontend interactivity and ViewComponents for UI components.

## Key Commands

### Development
```bash
bin/dev              # Start development server on port 3001
bin/rails db:setup   # Setup database with schema
bin/rails db:seed    # Seed with sample data
bin/rails console    # Rails console
```

### Testing
```bash
bin/rspec                                    # Run all RSpec tests
bin/rspec spec/models/paper_spec.rb         # Run specific test file
bin/e2e                                      # Run E2E tests (4 parallel workers)
bin/e2e --parallel[8]                        # Run E2E tests with 8 workers
bin/e2e e2e/playwright/e2e/visual_editor.spec.js  # Run specific E2E test

# For faster single file testing:
cd e2e && npx playwright test calendar.spec.js  # Run single test file directly
```

### Linting & Security
```bash
bundle exec rubocop                          # Run Ruby linter
bundle exec rubocop -a                       # Auto-fix Ruby linting issues
bundle exec brakeman                         # Run security scanner
yarn audit                                   # Check JavaScript vulnerabilities
```

### Asset Building
```bash
yarn build          # Build all assets
yarn watch:js       # Watch and rebuild JavaScript
yarn watch:css      # Watch and rebuild CSS
```

## Architecture & Structure

### Core Models
- **Paper**: Main model for Bitcoin paper wallets, handles wallet generation and rendering
- **User**: User accounts with authentication via Devise
- **Bundle**: Collection of papers for bulk operations
- **Token**: Authentication tokens for various purposes
- **Input**: Tracks Bitcoin inputs for funding wallets

### Frontend Architecture
- **ViewComponents** in `app/components/` for reusable UI (e.g., `Papers::LineItemComponent`)
- **Stimulus Controllers** in `app/javascript/controllers/` for client-side behavior
- **Turbo Streams** for real-time updates without page reloads
- **Tailwind CSS v4** for styling

### Key Features Implementation
- **Bitcoin Functionality**: Uses `bitcoin-ruby` gem with offline wallet generation capability
- **AI Design Generation**: Integrated via `ruby_llm` gem for custom wallet designs
- **Admin Interface**: ActiveAdmin at `/admin` route
- **Payment Processing**: Stripe integration for payments
- **Background Jobs**: SolidQueue for async processing

### Testing Approach
- **RSpec** for unit/integration tests with FactoryBot for test data
- **Playwright** for E2E browser testing across Chrome, Firefox, Safari
- **VCR** for recording HTTP interactions in tests
- **Parallel Tests** supported for faster test runs

### Database
- SQLite for all environments
- Separate databases for cache (SolidCache), queue (SolidQueue), and cable (SolidCable)
- Schema tracked in `db/schema.rb`

### Important Patterns
- Use ViewComponents for new UI components instead of partials
- Turbo Streams for dynamic updates (e.g., `app/views/papers/like.turbo_stream.erb`)
- Stimulus controllers for JavaScript behavior
- Admin resources defined in `app/admin/`
- Background jobs inherit from `ApplicationJob`

### Development Notes
- **Port 3001** is used for development server (not 3000)
- Credentials managed via Rails credentials (requires `master.key`)
- Submodules present - run `git submodule update --init --recursive` after cloning
- Environment variables via `.env` file
- Letter Opener used for email testing in development

## Hongbao Rails Development with ClaudeOnRails

This project uses ClaudeOnRails to create an intelligent swarm of AI agents specialized in different aspects of Rails development.

### How to Use

Simply describe what you want to build or fix, and the swarm will automatically coordinate the implementation:

```bash
# Start the swarm
claude-swarm orchestrate

# Then just describe your task
claude "Add user authentication with email confirmation"
claude "Optimize the dashboard queries that are running slowly"
claude "Create an API endpoint for mobile app integration"
```

### Swarm Architecture

The following specialized agents work together to implement your requests:

- **Architect**: Coordinates all development and makes high-level decisions
- **Models**: Handles ActiveRecord models, migrations, and database design
- **Controllers**: Manages request handling, routing, and controller logic
- **Views**: Creates and maintains views, View Components, layouts, and partials
- **Stimulus**: Implements interactive features with Stimulus controllers
- **Services**: Extracts business logic into service objects
- **Jobs**: Handles background processing and async tasks
- **Tests**: Ensures comprehensive test coverage with RSpec
- **DevOps**: Manages deployment and production configurations

## Project Conventions

### Code Style
- Follow Rails conventions and best practices
- Use RuboCop for Ruby style enforcement
- Prefer clarity over cleverness
- Write self-documenting code
- Keep controllers skinny - extract complex logic to concerns, helpers, or service objects

### View Development Best Practices

**Rails View Helpers:**
- Always use Rails view helpers instead of raw HTML tags when available:
  - `link_to` instead of `<a>` tags
  - `button_to` for form submission buttons
  - `form_with` instead of `<form>` tags
  - `image_tag` instead of `<img>` tags
  - `content_tag` for dynamic HTML elements

**Styling with DaisyUI:**
- Use DaisyUI semantic class names instead of raw Tailwind color utilities:
  - `bg-base-100`, `bg-base-200`, `bg-base-300` instead of `bg-white`, `bg-gray-50`, etc.
  - `text-base-content` instead of `text-gray-900` or `text-black`
  - `text-base-content/70` for muted text instead of `text-gray-600`
  - `border-base-300` instead of `border-gray-200`
  - `bg-primary`, `text-primary-content` for primary colors
  - `bg-secondary`, `text-secondary-content` for secondary colors
- This ensures automatic dark mode support without needing `dark:` prefixes

**Icons:**
- Use `heroicon` helper for icons: `<%= heroicon "arrow-right", variant: :outline, class: "w-5 h-5" %>`
- If an icon isn't available in heroicons, create a view helper in `app/helpers/icons_helper.rb`
- Never hardcode SVG icons directly in views

**Example Conversions:**
```erb
# ❌ Bad - Raw HTML with Tailwind colors
<a href="/path" class="text-blue-600 hover:text-blue-800">Link</a>
<button class="bg-orange-500 text-white">Submit</button>

# ✅ Good - Rails helpers with DaisyUI semantic classes
<%= link_to "Link", "/path", class: "text-primary hover:text-primary/80" %>
<%= button_to "Submit", "/path", class: "btn btn-primary" %>
```

### Testing
- RSpec for all tests except user interations.
- Fixtures for test data
- Request specs for API endpoints
- E2E playwright for user interactions

### E2E Testing Best Practices

When writing E2E tests with Playwright, use maintainable selectors that won't break easily with UI/UX changes:

**Good Selectors (Preferred):**
- Semantic roles: `page.getByRole('button', { name: 'Submit' })`
- Visible text: `page.getByText('Welcome to our site')`  
- Labels: `page.getByLabel('Email Address')`
- Placeholders: `page.getByPlaceholder('Enter your email')`
- ARIA attributes: `page.getByRole('navigation')`, `page.getByRole('main')`
- Readable CSS selectors (when necessary): `page.locator('.border-orange-500')` - Use semantic class names that describe the element's purpose/state

**Bad Selectors (Avoid):**
- Test IDs: `page.getByTestId('submit-form')` - Adds unnecessary attributes to production code
- CSS classes with responsive prefixes: `page.locator('.lg\\:col-span-4')` - Classes change with styling
- Generic elements: `page.locator('body')` - Too broad and brittle
- Complex CSS paths: `page.locator('div > span.text-sm')` - Tightly coupled to DOM structure
- nth-child selectors: `page.locator('li:nth-child(3)')` - Order may change

**Example:**
```javascript
// ❌ Bad - Uses test IDs or brittle selectors
await page.getByTestId('prev-month-button').click();
await page.locator('.lg\\:col-span-4').click();
await page.locator('body').fill('some text');

// ✅ Good - Uses semantic selectors
await page.getByRole('link', { name: 'Previous month' }).click();
await page.getByRole('button', { name: 'Save Event' }).click();
await page.getByLabel('Event Name').fill('Bitcoin Pizza Day');
await page.getByText('Delete Event').click();
```

The goal is to write tests that read like user stories and survive refactoring of the implementation details.

### Git Workflow
- Feature branches for new work
- Descriptive commit messages
- PR reviews before merging
- Keep main branch deployable

## Custom Patterns

Add your project-specific patterns and conventions here:

```yaml
# Example: Custom service object pattern
Services:
  Pattern: Command pattern with Result objects
  Location: app/services/
  Naming: VerbNoun (e.g., CreateOrder, SendEmail)
  Testing: Unit tests with mocked dependencies
```

## Notes

- This configuration was generated by ClaudeOnRails
- Customize agent prompts in `.claude-on-rails/prompts/`
- Update this file with project-specific conventions
- The swarm learns from your codebase patterns