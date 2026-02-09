# Testing Guidelines - Epic 2 UI Foundation

This document outlines the testing strategy and requirements for the UI components and flows developed in Epic 2.

## 1. Testing Stack

- **Minitest**: Primary testing framework.
- **ViewComponent::TestCase**: For unit testing individual components.
- **Capybara**: For system tests (end-to-end browser testing).
- **SimpleCov**: For code coverage monitoring.

## 2. Component Testing (Unit)

Every ViewComponent must have a corresponding test in `test/components/`.

### What to test:
- **Rendering**: Ensure the component renders the expected HTML structure.
- **Logic**: Test conditional rendering (e.g., status badge colors, empty states).
- **Slots**: If the component uses slots, verify they render correctly.
- **Accessibility**: Check for ARIA roles and labels in the rendered output.

### Example:
```ruby
class Artifacts::StatusBadgeComponentTest < ViewComponent::TestCase
  def test_renders_draft_status
    render_inline(Artifacts::StatusBadgeComponent.new(status: "draft"))
    assert_selector(".badge-ghost", text: "draft")
  end
end
```

## 3. Controller Testing (Integration)

Test controllers in `test/integration/` to ensure routing, parameter handling, and responses (including Turbo Streams) are correct.

### What to test:
- **HTTP Status Codes**: Verify 200 OK, 302 Redirect, 404 Not Found.
- **Turbo Streams**: Verify that Turbo Stream responses contain the expected `turbo-stream` tags and actions (append, replace, etc.).
- **Database Side Effects**: Verify that records are created or updated as expected.

## 4. System Testing (E2E)

Test full user flows in `test/system/` using Capybara.

### Key flows to cover:
- Dashboard initial load.
- Creating an artifact via slash command in chat.
- Navigating the artifact tree and viewing an artifact.
- Editing and saving an artifact.
- Verifying real-time updates (if applicable in test environment).

## 5. Accessibility Testing

- Use `test/integration/accessibility_test.rb` for automated checks (e.g., presence of landmarks, skip links).
- Manual verification with screen readers (VoiceOver) and keyboard-only navigation.

## 6. ViewComponent Previews

Use `test/components/previews/` to create previews for manual inspection and styling.
Previews are accessible at `/rails/view_components` in development.

## 7. Coverage Requirements

Maintain at least **90% code coverage** for all new code in Epic 2.
Run tests with `rails test` and check the report in `coverage/index.html`.
