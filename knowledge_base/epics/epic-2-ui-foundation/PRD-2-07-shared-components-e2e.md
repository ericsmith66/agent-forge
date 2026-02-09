#### PRD-2-07: Shared Components, Accessibility & E2E Validation

**PRD ID:** PRD-002.7  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-shared-e2e`  
**Dependencies:** PRD-002.3, PRD-002.4, PRD-002.5, PRD-002.6

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-07-shared-components-e2e-feedback-V{{N}}.md` in the same directory.

---

### Overview

Build the shared/reusable UI components (modals, toasts, loading states, command palette), perform an accessibility audit across all Epic 2 components, and add end-to-end integration tests that validate the full dashboard flow. This is the final PRD in Epic 2 — it polishes the UI foundation and ensures everything works together.

---

### Requirements

#### Functional

- **`Shared::ModalComponent`** (`app/components/shared/modal_component.rb`):
  - Reusable confirmation dialog (DaisyUI `modal`).
  - Props: `title` (string), `message` (string), `confirm_text` (string, default "Confirm"), `cancel_text` (string, default "Cancel"), `confirm_action` (URL or Turbo action).
  - Focus trap inside modal when open.
  - Closes on Escape key or clicking backdrop.
  - `modal` Stimulus controller for open/close behavior.

- **`Shared::ToastComponent`** (`app/components/shared/toast_component.rb`):
  - Success/error/info notification banner.
  - Auto-hides after 5 seconds (configurable).
  - Props: `message` (string), `type` (success/error/info/warning).
  - DaisyUI `toast` + `alert` classes.
  - `toast` Stimulus controller for auto-hide and manual dismiss.

- **`Shared::LoadingComponent`** (`app/components/shared/loading_component.rb`):
  - Spinner and skeleton loading states.
  - Props: `type` (:spinner or :skeleton), `size` (:sm, :md, :lg).
  - Used as placeholder content in Turbo Frames while loading.

- **`Shared::CommandPaletteComponent`** (`app/components/shared/command_palette_component.rb`):
  - Global search overlay triggered by Cmd+K (or Ctrl+K).
  - Search input with results list (artifacts, commands, projects).
  - Keyboard navigation (↑↓ to navigate, Enter to select, Escape to close).
  - `command_palette` Stimulus controller.
  - For now, searches artifacts by title (client-side filter from preloaded data or server-side via Turbo Frame).

- **Accessibility audit & fixes**:
  - Skip link ("Skip to main content") at top of page.
  - All icon-only buttons have `aria-label`.
  - All form inputs have associated `<label>` elements.
  - Focus visible on all interactive elements (ring/outline).
  - `aria-live="polite"` on chat message container and toast container.
  - `role="tree"` / `role="treeitem"` on sidebar (verify from PRD-2-04).
  - Color contrast meets WCAG AA (4.5:1 for text, 3:1 for UI).
  - Tab order is logical (navbar → sidebar → chat → viewer).

- **ViewComponent previews**:
  - Set up ViewComponent preview infrastructure (`test/components/previews/`).
  - Create previews for key components: DashboardComponent, TreeComponent, BubbleComponent, ViewerComponent, DiffPreviewComponent, ModalComponent, ToastComponent.
  - Accessible at `/rails/view_components` in development.

#### Non-Functional

- All shared components render in <50ms.
- Command palette search responds in <100ms for up to 500 artifacts.
- Toast auto-hide uses CSS transitions (no layout jank).
- All components work with DaisyUI dark and light themes.

#### Rails / Implementation Notes

- `app/components/shared/modal_component.rb` + `.html.erb`
- `app/components/shared/toast_component.rb` + `.html.erb`
- `app/components/shared/loading_component.rb` + `.html.erb`
- `app/components/shared/command_palette_component.rb` + `.html.erb`
- `app/javascript/controllers/modal_controller.js`
- `app/javascript/controllers/toast_controller.js`
- `app/javascript/controllers/command_palette_controller.js`
- `test/components/previews/` — ViewComponent preview classes.
- Update `app/views/layouts/application.html.erb` with skip link and toast container.

---

### Error Scenarios & Fallbacks

- **Command palette search returns no results** → Show "No results found" message.
- **Modal confirm action fails** → Show toast with error message; don't close modal.
- **JavaScript disabled** → Modals degrade to standard Rails confirm dialogs. Toasts render as flash messages. Command palette unavailable (acceptable).

---

### Architectural Context

Shared components are the **utility layer** — reusable across all panes and features. They enforce consistent UX patterns (confirmation before destructive actions, feedback via toasts, loading states during async operations). The command palette provides quick navigation as the artifact count grows. This PRD also serves as the **integration checkpoint** for Epic 2 — the E2E tests prove all components work together.

---

### Acceptance Criteria

- [ ] Modal opens/closes with focus trap and Escape key.
- [ ] Toast shows success/error messages and auto-hides after 5s.
- [ ] Loading spinner and skeleton render correctly.
- [ ] Command palette opens on Cmd+K, searches artifacts, navigates on Enter.
- [ ] Skip link present and functional ("Skip to main content").
- [ ] All icon-only buttons have `aria-label`.
- [ ] All form inputs have `<label>` elements.
- [ ] Focus visible on all interactive elements.
- [ ] Tab order is logical across all panes.
- [ ] ViewComponent previews accessible at `/rails/view_components`.
- [ ] E2E test passes: create artifact via chat → see in tree → view → edit → save.
- [ ] SimpleCov ≥ 90% for all Epic 2 code (models, components, controllers, services).
- [ ] All tests pass (unit, integration, system).

---

### Test Cases

#### Unit (Minitest — ViewComponent::TestCase)

- `test/components/shared/modal_component_test.rb`:
  - Renders title, message, confirm/cancel buttons.
  - Confirm button has correct action URL.

- `test/components/shared/toast_component_test.rb`:
  - Renders message with correct alert class per type.
  - Contains dismiss button.

- `test/components/shared/loading_component_test.rb`:
  - Renders spinner for `:spinner` type.
  - Renders skeleton for `:skeleton` type.

- `test/components/shared/command_palette_component_test.rb`:
  - Renders search input.
  - Renders results list.

#### Integration (Minitest)

- `test/integration/full_dashboard_flow_test.rb`:
  - GET `/` → redirects to project dashboard → 200.
  - Dashboard contains all 4 panes (navbar, sidebar, chat, viewer).
  - POST message with `/new-epic Test Epic` → creates artifact → returns Turbo Stream.
  - GET artifact show → viewer renders artifact content.
  - GET artifact edit → editor form renders.
  - PATCH artifact update → saves and redirects to viewer.

#### System (Capybara)

- `test/system/dashboard_test.rb`:
  - Visit dashboard → 4-pane layout visible.
  - Click artifact in sidebar → viewer updates (no page reload).
  - Type message in chat → submit → bubbles appear.
  - Type `/new-epic My Test` → artifact created → appears in sidebar.
  - Click Edit on artifact → editor loads → change title → save → viewer shows updated title.

#### Accessibility

- `test/integration/accessibility_test.rb`:
  - Dashboard page has skip link.
  - All images/icons have alt text or aria-label.
  - No duplicate IDs on page.
  - Landmark roles present (navigation, main, complementary).

---

### Manual Verification

1. Open dashboard — verify all 4 panes render.
2. Press Cmd+K — command palette opens. Type artifact name — results filter. Press Enter — navigates.
3. Press Escape — palette closes.
4. Create artifact via `/new-epic` in chat — toast shows "Epic created".
5. Click artifact — viewer loads. Click Edit — editor loads. Save — toast shows "Saved".
6. Tab through page — verify logical focus order.
7. Use screen reader (VoiceOver on Mac) — verify landmarks and labels announced.
8. Open `/rails/view_components` — verify component previews render.
9. Run full test suite: `bin/rails test` — all green.
10. Check coverage: `open coverage/index.html` — ≥ 90%.

**Expected**
- All shared components work correctly.
- Full flow (create → view → edit → save) works end-to-end.
- Accessibility requirements met.
- Test coverage ≥ 90%.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Reference `knowledge_base/epics/epic-2-ui-foundation/JAVASCRIPT-ARCHITECTURE.md` for modal, toast, command_palette controller specs.
- For Capybara system tests, ensure `gem 'capybara'` and `gem 'selenium-webdriver'` are in Gemfile (test group).
- ViewComponent previews require `config.view_component.preview_paths << Rails.root.join("test/components/previews")` in `config/application.rb`.
- This is the final PRD in Epic 2. After completion, update `knowledge_base/epics/epic-2-ui-foundation/0001-IMPLEMENTATION-STATUS.md`.
- Commit message suggestion: `"Implement PRD-002.7: Shared components, accessibility & E2E validation"`
