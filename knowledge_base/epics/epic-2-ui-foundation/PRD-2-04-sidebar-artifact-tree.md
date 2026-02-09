#### PRD-2-04: Artifact Sidebar Tree & Navigation

**PRD ID:** PRD-002.4  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-sidebar`  
**Dependencies:** PRD-002.2, PRD-002.3

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-04-sidebar-artifact-tree-feedback-V{{N}}.md` in the same directory.

---

### Overview

Build the left sidebar artifact tree that displays the project's artifact hierarchy (Ideas, Epics, PRDs) in a collapsible, navigable tree. Clicking an artifact loads its content in the right viewer pane via Turbo Frame. The tree supports keyboard navigation and status badges for each artifact.

---

### Requirements

#### Functional

- **`Artifacts::TreeComponent`** (`app/components/artifacts/tree_component.rb`):
  - Groups artifacts by type: Ideas, Backlog Items, Epics (with nested PRDs).
  - Each group is collapsible (DaisyUI `collapse` or HTML `<details>`).
  - Highlights the currently selected artifact.
  - Shows child count per group (e.g., "Epics (3)").
  - Props: `project` (Project), `current_artifact` (optional).
  - Wrapped in `turbo_frame_tag "artifact_tree"`.

- **`Artifacts::TreeItemComponent`** (`app/components/artifacts/tree_item_component.rb`):
  - Renders single artifact node: icon (by type), title (truncated), status badge.
  - Nested children rendered recursively (Epic → PRDs indented).
  - Click navigates via Turbo Frame target `artifact_viewer`.
  - Props: `artifact` (Artifact), `selected` (boolean), `depth` (integer for indentation).

- **`Artifacts::StatusBadgeComponent`** (`app/components/artifacts/status_badge_component.rb`):
  - Renders colored badge: draft (gray), refined (blue), approved (green), implemented (purple), archived (dim).
  - Uses DaisyUI `badge` classes.
  - Props: `status` (string).

- **`ArtifactsController`** (`app/controllers/artifacts_controller.rb`):
  - `index` action: returns tree HTML for Turbo Frame refresh.
  - `show` action: returns artifact viewer HTML for Turbo Frame `artifact_viewer`.
  - Scoped to project: `GET /projects/:project_id/artifacts` and `GET /projects/:project_id/artifacts/:id`.

- **`tree_navigation` Stimulus controller** (`app/javascript/controllers/tree_navigation_controller.js`):
  - Arrow keys: ↑/↓ move focus between items, ←/→ collapse/expand groups.
  - Enter: select focused item (triggers Turbo Frame navigation).
  - Focus visible: highlighted item has ring/outline.

#### Non-Functional

- Tree renders in <100ms for up to 100 artifacts.
- Accessible: `role="tree"`, `role="treeitem"`, `aria-expanded`, `aria-selected`.
- Empty state: "No artifacts yet — use /new-epic in chat to create one."

#### Rails / Implementation Notes

- `app/components/artifacts/tree_component.rb` + `.html.erb`
- `app/components/artifacts/tree_item_component.rb` + `.html.erb`
- `app/components/artifacts/status_badge_component.rb` + `.html.erb`
- `app/controllers/artifacts_controller.rb`
- `app/javascript/controllers/tree_navigation_controller.js`
- Routes: `resources :artifacts, only: [:index, :show]` nested under `resources :projects`.

---

### Error Scenarios & Fallbacks

- **No artifacts** → Empty state message with instructions.
- **Deeply nested hierarchy** → Cap rendering at 3 levels (Epic → PRD → sub-item). Log warning if deeper.
- **Artifact deleted while viewing** → Turbo Frame returns 404 → show "Artifact not found" in viewer pane.

---

### Architectural Context

The sidebar tree is the **navigation hub** for artifacts. It is read-only — it renders data from the Artifact model but never modifies it. Clicking a tree item triggers a Turbo Frame request that updates the viewer pane (PRD-2-06). The tree refreshes via Turbo Stream when artifacts are created/updated (wired in PRD-2-05).

```
Sidebar (TreeComponent)          Viewer Pane
├── Ideas                        ┌──────────────────┐
├── Epics                        │ ViewerComponent   │
│   ├── Epic 1  ──click──────►   │ (loaded via       │
│   │   ├── PRD 1.1              │  Turbo Frame)     │
│   │   └── PRD 1.2              └──────────────────┘
│   └── Epic 2
└── Backlog Items
```

---

### Acceptance Criteria

- [ ] Tree renders grouped artifacts (Ideas, Epics with nested PRDs, Backlog Items).
- [ ] Groups are collapsible/expandable.
- [ ] Clicking artifact loads viewer pane via Turbo Frame (no full page reload).
- [ ] Current artifact is highlighted in tree.
- [ ] Status badges display correct colors for each status.
- [ ] Keyboard navigation works (↑↓←→ Enter).
- [ ] Empty state renders when no artifacts exist.
- [ ] ARIA tree roles present (`role="tree"`, `role="treeitem"`).
- [ ] All component and controller tests pass.

---

### Test Cases

#### Unit (Minitest — ViewComponent::TestCase)

- `test/components/artifacts/tree_component_test.rb`:
  - Renders grouped artifacts by type.
  - Highlights current artifact.
  - Renders empty state when no artifacts.
  - Contains Turbo Frame wrapper.

- `test/components/artifacts/tree_item_component_test.rb`:
  - Renders title, icon, status badge.
  - Renders nested children with indentation.
  - Link targets `artifact_viewer` Turbo Frame.

- `test/components/artifacts/status_badge_component_test.rb`:
  - Renders correct badge class for each status (draft, refined, approved, implemented, archived).

#### Integration (Minitest)

- `test/integration/artifacts_controller_test.rb`:
  - GET `/projects/:id/artifacts` returns 200 with tree HTML.
  - GET `/projects/:id/artifacts/:id` returns 200 with viewer HTML.
  - GET `/projects/:id/artifacts/999` returns 404.

---

### Manual Verification

1. Seed database with sample artifacts (`bin/rails db:seed`).
2. Open dashboard — sidebar shows artifact tree.
3. Click an Epic — viewer pane loads artifact content (or placeholder).
4. Collapse/expand groups — works smoothly.
5. Use keyboard (↑↓←→ Enter) — focus moves, items select.
6. Resize to mobile — sidebar becomes drawer.

**Expected**
- Tree renders all artifacts in correct hierarchy.
- Navigation updates viewer pane without page reload.
- Keyboard and mouse navigation both work.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Reference `knowledge_base/epics/epic-2-ui-foundation/COMPONENT-RESPONSIBILITY-MATRIX.md` for TreeComponent specs.
- Reference `knowledge_base/epics/epic-2-ui-foundation/JAVASCRIPT-ARCHITECTURE.md` for tree_navigation controller spec.
- The viewer pane content (PRD-2-06) can be a placeholder for now — just render artifact title and status.
- Commit message suggestion: `"Implement PRD-002.4: Artifact sidebar tree & navigation"`
