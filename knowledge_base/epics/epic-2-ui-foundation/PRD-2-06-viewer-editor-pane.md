#### PRD-2-06: Artifact Viewer & Editor Pane

**PRD ID:** PRD-002.6  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-viewer`  
**Dependencies:** PRD-002.2, PRD-002.3, PRD-002.4

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-06-viewer-editor-pane-feedback-V{{N}}.md` in the same directory.

---

### Overview

Build the right-side viewer/editor pane that displays artifact content and allows editing. When a user clicks an artifact in the sidebar tree, the viewer loads via Turbo Frame showing the artifact's JSONB document rendered as formatted markdown. An "Edit" button switches to an editor form with autosave. This PRD also includes a mock diff preview component using sample diffs (real AiderDesk integration deferred).

---

### Requirements

#### Functional

- **`Artifacts::ViewerComponent`** (`app/components/artifacts/viewer_component.rb`):
  - Renders artifact metadata: title, type, status badge, created/updated timestamps.
  - Renders `jsonb_document` sections as formatted markdown (using `render_markdown` helper).
  - "Edit" button switches to editor (via Turbo Frame navigation to edit action).
  - "Back to list" link (for mobile, where viewer is full-screen).
  - Props: `artifact` (Artifact).
  - Wrapped in `turbo_frame_tag "artifact_viewer"`.

- **`Artifacts::EditorComponent`** (`app/components/artifacts/editor_component.rb`):
  - Form for editing artifact: title (text input), status (select dropdown), jsonb_document sections (textarea per section or single large textarea).
  - Submit saves via PATCH to `ArtifactsController#update`.
  - Cancel returns to viewer.
  - Props: `artifact` (Artifact).
  - Wrapped in `turbo_frame_tag "artifact_viewer"`.

- **`Artifacts::DiffPreviewComponent`** (`app/components/artifacts/diff_preview_component.rb`):
  - Renders code diff in unified or side-by-side view.
  - Syntax highlighting (basic: additions green, deletions red, context gray).
  - File path header and diff stats (e.g., "+12 -3").
  - Accept/Reject buttons (placeholder — wired to confirmation modal but no backend action yet).
  - Props: `diff` (hash with `:path`, `:original`, `:updated`, `:stats`).
  - Uses mock/sample diffs for now (stored in a helper or fixture).

- **`diff_viewer` Stimulus controller** (`app/javascript/controllers/diff_viewer_controller.js`):
  - Toggle between unified and side-by-side view.
  - Copy diff to clipboard button.

- **`autosave` Stimulus controller** (`app/javascript/controllers/autosave_controller.js`):
  - Debounced save (2s after last input).
  - Shows "Saving..." / "Saved" indicator.
  - Submits form via fetch, updates status without page reload.

- **`render_markdown` helper** (`app/helpers/markdown_helper.rb`):
  - Converts markdown text to sanitized HTML using `commonmarker` gem.
  - Disables raw HTML in user content (`render: { unsafe: false }`).
  - Returns empty string for blank input.

- **`ArtifactsController`** updates:
  - `edit` action: renders EditorComponent in `artifact_viewer` Turbo Frame.
  - `update` action: saves artifact, redirects to show (viewer) in Turbo Frame.
  - Responds to both HTML and Turbo Stream formats.

#### Non-Functional

- Viewer renders markdown in <200ms for typical artifact content.
- Editor autosave debounced at 2s — no save on every keystroke.
- Diff preview handles diffs up to 500 lines without performance issues.
- Accessible: form labels, error messages linked to fields, focus management on mode switch.

#### Rails / Implementation Notes

- `app/components/artifacts/viewer_component.rb` + `.html.erb`
- `app/components/artifacts/editor_component.rb` + `.html.erb`
- `app/components/artifacts/diff_preview_component.rb` + `.html.erb`
- `app/helpers/markdown_helper.rb`
- `app/javascript/controllers/autosave_controller.js`
- `app/javascript/controllers/diff_viewer_controller.js`
- Update `app/controllers/artifacts_controller.rb` with `edit`, `update` actions.
- Update routes: add `edit` and `update` to artifacts resource.
- Sample diffs: create `app/helpers/sample_diffs_helper.rb` or fixture data for diff preview testing.

---

### Error Scenarios & Fallbacks

- **Artifact not found** → Viewer shows "Artifact not found" message in Turbo Frame.
- **Validation error on save** → Re-render editor with inline errors (Turbo re-renders form).
- **Autosave fails** → Show "Save failed — retry" indicator. Don't lose user input.
- **Markdown rendering error** → Fall back to plain text display. Log error.
- **Empty jsonb_document** → Viewer shows "No content yet — click Edit to add content."

---

### Architectural Context

The viewer/editor pane is the **detail view** for artifacts. It loads inside the `artifact_viewer` Turbo Frame, so switching between artifacts or toggling view/edit mode happens without full page reloads. The diff preview is a standalone component that will later receive real diffs from the ToolAdapter (Epic 1) when the `/implement` command is wired up (Epic 4).

```
Sidebar click → Turbo Frame GET /projects/:id/artifacts/:id
  → ArtifactsController#show
    → Renders ViewerComponent in "artifact_viewer" frame

"Edit" click → Turbo Frame GET /projects/:id/artifacts/:id/edit
  → ArtifactsController#edit
    → Renders EditorComponent in "artifact_viewer" frame

Save → PATCH /projects/:id/artifacts/:id
  → ArtifactsController#update
    → Redirects to show → ViewerComponent re-renders
```

---

### Acceptance Criteria

- [ ] Clicking artifact in tree loads viewer in right pane (Turbo Frame, no page reload).
- [ ] Viewer renders artifact title, type, status, timestamps, and markdown content.
- [ ] "Edit" button switches to editor form in same pane.
- [ ] Editor saves artifact on submit; returns to viewer with updated content.
- [ ] Autosave triggers after 2s of inactivity; shows "Saved" indicator.
- [ ] Diff preview renders sample diff with syntax highlighting.
- [ ] Diff toggle (unified/side-by-side) works.
- [ ] Empty artifact shows "No content" placeholder.
- [ ] Validation errors display inline in editor.
- [ ] `render_markdown` helper sanitizes HTML and renders markdown correctly.
- [ ] All component, controller, and helper tests pass.

---

### Test Cases

#### Unit (Minitest — ViewComponent::TestCase)

- `test/components/artifacts/viewer_component_test.rb`:
  - Renders title, type badge, status badge, timestamps.
  - Renders markdown content from jsonb_document.
  - Shows "Edit" button.
  - Shows "No content" for empty document.

- `test/components/artifacts/editor_component_test.rb`:
  - Renders form with title, status, content fields.
  - Form action points to update path.
  - Pre-fills fields with artifact data.

- `test/components/artifacts/diff_preview_component_test.rb`:
  - Renders file path header.
  - Renders additions (green) and deletions (red).
  - Renders diff stats.
  - Shows Accept/Reject buttons.

#### Unit (Minitest — Helper)

- `test/helpers/markdown_helper_test.rb`:
  - Renders markdown to HTML.
  - Sanitizes raw HTML tags.
  - Returns empty string for blank input.
  - Handles malformed markdown gracefully.

#### Integration (Minitest)

- `test/integration/artifacts_controller_test.rb` (extend from PRD-2-04):
  - GET `/projects/:id/artifacts/:id/edit` returns 200 with editor form.
  - PATCH `/projects/:id/artifacts/:id` updates artifact and redirects.
  - PATCH with invalid data re-renders editor with errors.

---

### Manual Verification

1. Seed database, open dashboard.
2. Click an artifact in sidebar — viewer loads in right pane.
3. Verify markdown renders correctly (headers, lists, code blocks).
4. Click "Edit" — editor form appears in same pane.
5. Change title, click Save — returns to viewer with updated title.
6. Test autosave: edit content, wait 2s — "Saved" indicator appears.
7. Navigate to diff preview (via direct URL or placeholder link) — sample diff renders.
8. Toggle unified/side-by-side — view switches.

**Expected**
- Viewer and editor work seamlessly within Turbo Frame.
- Markdown renders correctly.
- Autosave works without page reload.
- Diff preview displays sample diffs with highlighting.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Reference `knowledge_base/epics/epic-2-ui-foundation/COMPONENT-RESPONSIBILITY-MATRIX.md` for ViewerComponent and EditorComponent specs.
- For diff preview, create 2-3 sample diffs (Ruby file change, ERB template change, markdown change) as fixture data.
- The `commonmarker` gem should already be in Gemfile from PRD-2-01. If not, add it.
- Commit message suggestion: `"Implement PRD-002.6: Artifact viewer, editor & diff preview components"`
