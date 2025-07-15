# Coding Style Guide for Hongbao

This document outlines the coding standards and conventions for the Hongbao project.

## General Rules

### 1. Whitespace and Formatting
- **No trailing whitespace** on any line
- **Always end files with a newline character**
- Use 2 spaces for indentation (no tabs)
- No unnecessary blank lines at the beginning or end of files

### 2. Ruby/Rails Conventions
- Follow the Rails Omakase style guide (configured in .rubocop.yml)
- Use `update_columns` instead of `save!` when you need to skip callbacks
- Prefer fixtures over factories in tests
- Use meaningful variable and method names

### 3. ERB Templates
- Keep logic minimal in views
- Use ViewComponents for reusable UI elements
- Properly indent HTML within ERB tags

### 4. JavaScript/Stimulus
- Use Stimulus controllers for JavaScript behavior
- Follow Rails conventions for data attributes
- Avoid inline JavaScript (onclick, etc.)

### 5. CSS/Tailwind
- Use Tailwind utility classes
- Avoid custom CSS when possible
- Group related classes logically

### 6. Testing
- Write specs for all new functionality
- Use fixtures for test data (located in spec/fixtures/)
- Avoid `allow_any_instance_of` - use proper test setup instead
- For components that need controller context, use `update_columns` to avoid triggering callbacks

### 7. Git Commits
- Write clear, concise commit messages
- Reference issue numbers when applicable
- Keep commits focused on a single change

## File Structure Examples

### Ruby Files
```ruby
# Good - ends with newline, no trailing spaces
class Example
  def method
    # code here
  end
end
```

### ERB Files
```erb
<!-- Good - proper indentation, no trailing spaces -->
<div class="container">
  <%= render Component.new(item: @item) %>
</div>
```

### Avoiding Common Issues

1. **Trailing Spaces**: Configure your editor to show and remove trailing spaces
2. **Missing Newlines**: Configure your editor to ensure files end with a newline
3. **Nested Interactive Elements**: Don't put buttons/links inside other buttons/links
4. **Callback Issues in Tests**: Use `update_columns` instead of `save!` when testing models with broadcast callbacks

## Editor Configuration

### VS Code
```json
{
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true
}
```

### Vim
```vim
set list listchars=trail:·,tab:»·
autocmd BufWritePre * %s/\s\+$//e
set eol
```

## Pre-commit Checks

Run these before committing:
- `bundle exec rubocop` - Ruby linting
- `bin/rspec` - Run tests
- `git diff --check` - Check for whitespace errors