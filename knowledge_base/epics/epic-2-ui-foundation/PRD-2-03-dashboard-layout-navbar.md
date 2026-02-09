#### PRD-2-03: Dashboard Layout Shell & Navbar

**PRD ID:** PRD-002.3  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-layout`  
**Dependencies:** PRD-002.1, PRD-002.2

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-03-dashboard-layout-navbar-feedback-V{{N}}.md` in the same directory.

---

### Overview

Build the 4-pane dashboard layout shell and top navbar. This is the visual skeleton that all other UI components plug into. The layout uses CSS Grid with responsive breakpoints: 3-pane on desktop (sidebar + chat + viewer), 2-column on tablet, single-column with drawer sidebar on mobile. The navbar provides project switching, agent status indicator, and user menu.

---

### Requirements

#### Functional

- **`Layouts::DashboardComponent`** (`app/components/layouts/dashboard_component.rb`):
  - Renders 4 regions: navbar (top), sidebar (left), chat (center), viewer (right).
  - CSS Grid layout with responsive breakpoints per WIREFRAMES.md.
  - Props: `project` (Project model), `current_artifact` (optional), `current_task` (optional).
  - Sets up Turbo Frame targets: `artifact_tree`, `chat_messages`, `artifact_viewer`.
  - DaisyUI drawer for mobile sidebar (hamburger toggle).

- **`Layouts::NavbarComponent`** (`app/components/layouts/navbar_component.rb`):
  - Logo/brand text ("Agent-Forge").
  - Project switcher dropdown (list of active projects, current project highlighted).
  - Agent status indicator (placeholder: green dot + "Ready" text).
  - User menu dropdown (placeholder: avatar + "Settings" / "Sign Out" links).
  - Hamburger button on mobile (toggles sidebar drawer).

- **`Projects::SwitcherComponent`** (`app/components/projects/switcher_component.rb`):
  - Dropdown listing all active projects.
  - Current project highlighted.
  - Clicking a project navigates to `/projects/:id/dashboard`.
  - `project_switcher` Stimulus controller for dropdown open/close and keyboard nav.

- **`DashboardController`** updates:
  - `show` action loads current project (first active project or from params).
  - Passes project, artifacts, current task to DashboardComponent.
  - Route: `GET /projects/:project_id/dashboard` + root route redirects to first project's dashboard.

- **Responsive behavior**:
  - `≥1024px`: 3-pane (20% sidebar, 50% chat, 30% viewer).
  - `768–1023px`: 2-column (chat full width, sidebar as drawer, viewer as overlay/tab).
  - `<768px`: Single column (chat only, sidebar drawer, viewer navigated to separately).

#### Non-Functional

- All panes have independent scroll (overflow-y-auto).
- Navbar fixed at top (64px height).
- Sidebar, chat, and viewer fill remaining viewport height (`calc(100vh - 64px)`).
- DaisyUI theme: use `data-theme="dark"` or `data-theme="light"` (configurable, default dark).
- Semantic HTML: `<nav>`, `<aside>`, `<main>`, `<section>`.
- ARIA landmarks: `role="navigation"`, `role="complementary"` (sidebar), `role="main"` (chat).

#### Rails / Implementation Notes

- `app/components/layouts/dashboard_component.rb` + `.html.erb`
- `app/components/layouts/navbar_component.rb` + `.html.erb`
- `app/components/projects/switcher_component.rb` + `.html.erb`
- `app/javascript/controllers/project_switcher_controller.js`
- Update `app/controllers/dashboard_controller.rb`
- Update `config/routes.rb` with project-scoped dashboard route.
- Update `app/views/layouts/application.html.erb` to include DaisyUI CDN link.

---

### Error Scenarios & Fallbacks

- **No projects exist** → Dashboard shows "Create your first project" placeholder with instructions.
- **Project not found** → Redirect to root with flash error.
- **JavaScript disabled** → Layout still renders (CSS Grid works without JS). Sidebar always visible on desktop. Drawer won't toggle on mobile — acceptable degradation.

---

### Architectural Context

The dashboard layout is the **container** for all UI components. It does not contain business logic — it orchestrates rendering of child components (tree, chat, viewer) within a responsive grid. Turbo Frames enable each pane to update independently without full page reloads.

```
┌────────────────────────────────────────────────────────┐
│  NavbarComponent (fixed top)                            │
├──────────┬─────────────────────┬───────────────────────┤
│ Sidebar  │  Chat Pane          │  Viewer Pane           │
│ (Turbo   │  (Turbo Frame:      │  (Turbo Frame:         │
│  Frame:  │   chat_messages)    │   artifact_viewer)     │
│  artifact│                     │                        │
│  _tree)  │  [PRD-2-05]         │  [PRD-2-06]            │
│          │                     │                        │
│ [PRD-2-04]                     │                        │
└──────────┴─────────────────────┴───────────────────────┘
```

---

### Acceptance Criteria

- [ ] Dashboard renders 3-pane layout on desktop (≥1024px).
- [ ] Dashboard collapses to single-column on mobile (<768px).
- [ ] Navbar displays logo, project switcher, agent status, user menu.
- [ ] Project switcher dropdown lists active projects and navigates on click.
- [ ] Hamburger button toggles sidebar drawer on mobile.
- [ ] Each pane scrolls independently.
- [ ] Turbo Frame targets (`artifact_tree`, `chat_messages`, `artifact_viewer`) present in DOM.
- [ ] Semantic HTML and ARIA landmarks in place.
- [ ] "No projects" state renders placeholder message.
- [ ] All component tests pass.

---

### Test Cases

#### Unit (Minitest — ViewComponent::TestCase)

- `test/components/layouts/dashboard_component_test.rb`:
  - Renders all 4 regions (navbar, sidebar, chat, viewer).
  - Contains Turbo Frame targets.
  - Renders "no projects" state when project is nil.

- `test/components/layouts/navbar_component_test.rb`:
  - Renders logo, project switcher, agent status, user menu.
  - Renders hamburger button.

- `test/components/projects/switcher_component_test.rb`:
  - Lists active projects.
  - Highlights current project.
  - Renders empty state when no projects.

#### Integration (Minitest)

- `test/integration/dashboard_test.rb`:
  - GET `/` redirects to first project's dashboard (or shows "no projects").
  - GET `/projects/:id/dashboard` returns 200 with layout.

---

### Manual Verification

1. Run `bin/rails server`.
2. Open `http://localhost:3000` — redirects to project dashboard.
3. Resize browser: verify 3-pane → 2-column → single-column transitions.
4. Click hamburger on mobile — sidebar drawer opens.
5. Click project in switcher — navigates to that project's dashboard.
6. Inspect DOM: verify Turbo Frame targets and ARIA landmarks.

**Expected**
- Responsive 4-pane layout renders correctly at all breakpoints.
- Navigation works without full page reloads.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Reference `knowledge_base/epics/epic-2-ui-foundation/WIREFRAMES.md` for exact layout specs.
- Reference `knowledge_base/epics/epic-2-ui-foundation/COMPONENT-RESPONSIBILITY-MATRIX.md` for component boundaries.
- Use DaisyUI classes: `drawer`, `navbar`, `dropdown`, `menu`, `btn`.
- Use Tailwind responsive prefixes: `lg:grid-cols-[1fr_2fr_1.5fr]`, `md:grid-cols-2`.
- Commit message suggestion: `"Implement PRD-002.3: Dashboard layout shell & navbar components"`
