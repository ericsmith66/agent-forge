# Coding Standards for agent-forge

1. **Testing Framework**: Use **Minitest** exclusively. Do NOT use RSpec. Refer to existing tests for Capybara and VCR patterns.
2. **Components**: Prefer **ViewComponent** for UI logic. Keep components in `app/components/`.
3. **Styling**: Use **Tailwind CSS** with **DaisyUI** classes. Follow the established utility-first patterns.
4. **Service Pattern**: Business logic should reside in `app/services/` or `lib/agents/`.
5. **Turbo/Hotwire**: Use `turbo_frame_tag` and `turbo_stream` for reactive updates. Ensure IDs are unique and match the 3-pane layout conventions.
6. **Logging**: Follow `knowledge_base/ai-instructions/junie-log-requirement.md`. Log significant events to `Rails.logger`.
7. **Ruby/Rails Version**: Ruby 3.3+ with Rails 8.1+. See `knowledge_base/epics/epic-1-bootstrap/BASELINE-GEMFILE.md` for the baseline stack (Devise, Pundit, AI-Agents).
8. **Modern Syntax**: Use modern Ruby syntax (e.g., shorthand hash keys `{ name: }`).
9. **Documentation**: Keep KDocs and `knowledge_base` documents updated when logic changes.
