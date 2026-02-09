#### PRD-2-02: Core Data Models & Migrations

**PRD ID:** PRD-002.2  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-models`  
**Dependencies:** PRD-002.1

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-02-core-models-feedback-V{{N}}.md` in the same directory.

---

### Overview

Create the core data models that back the agent-forge UI: Project, Artifact, Task, and Message. These models use PostgreSQL JSONB columns for flexible document storage (artifact content, task metadata, message payloads). This PRD establishes the data layer that all UI components read from and write to.

---

### Requirements

#### Functional

- **Project** model:
  - `name` (string, required, unique)
  - `description` (text, optional)
  - `project_dir` (string, required) — absolute path to project directory under `projects/`
  - `settings` (jsonb, default `{}`) — project-level config (model preferences, etc.)
  - `active` (boolean, default `true`)
  - Associations: `has_many :artifacts`, `has_many :tasks`
  - Validation: `project_dir` must be under `projects/` (reuse validation pattern from ToolAdapter)

- **Artifact** model:
  - `project_id` (references, required)
  - `parent_id` (self-referential, optional) — for hierarchy (Epic → PRD)
  - `artifact_type` (string enum: `idea`, `backlog_item`, `epic`, `prd`)
  - `title` (string, required)
  - `jsonb_document` (jsonb, default `{}`) — structured content (sections, goals, criteria, etc.)
  - `status` (string enum: `draft`, `refined`, `approved`, `implemented`, `archived`)
  - `position` (integer) — ordering within parent
  - Associations: `belongs_to :project`, `belongs_to :parent` (optional, class: Artifact), `has_many :children` (class: Artifact, foreign_key: :parent_id)
  - Scopes: `by_type(type)`, `by_status(status)`, `roots` (where parent_id is nil), `ordered` (by position)

- **Task** model:
  - `project_id` (references, required)
  - `name` (string, optional)
  - `status` (string enum: `pending`, `in_progress`, `completed`, `failed`, `timeout`)
  - `aider_desk_task_id` (string, optional) — maps to AiderDesk task UUID
  - `metadata` (jsonb, default `{}`) — diffs, tool call results, etc.
  - Associations: `belongs_to :project`, `has_many :messages`

- **Message** model:
  - `task_id` (references, required)
  - `role` (string enum: `user`, `assistant`, `system`, `tool`)
  - `content` (text, required)
  - `metadata` (jsonb, default `{}`) — tool call details, timestamps, etc.
  - Associations: `belongs_to :task`
  - Scope: `ordered` (by created_at asc)

- **Seeds**: Create one sample project pointing to `projects/aider-desk-test`, with a sample Epic artifact containing two child PRD artifacts, and one task with a few messages.

#### Non-Functional

- All JSONB columns default to `{}` (never null).
- Indexes on: `artifacts.project_id`, `artifacts.parent_id`, `artifacts.artifact_type`, `artifacts.status`, `tasks.project_id`, `tasks.aider_desk_task_id`, `messages.task_id`.
- Enum values stored as strings (not integers) for readability.
- 90% test coverage on model validations and scopes.

#### Rails / Implementation Notes

- `app/models/project.rb`, `app/models/artifact.rb`, `app/models/task.rb`, `app/models/message.rb`
- Migrations in `db/migrate/`
- Seeds in `db/seeds.rb`
- Use Rails 7+ `enum` syntax: `enum :status, { draft: "draft", refined: "refined", ... }`

---

### Error Scenarios & Fallbacks

- **Invalid `project_dir`** → Validation error: "must be under projects/".
- **Orphaned artifacts** (parent deleted) → `dependent: :nullify` on parent association (don't cascade delete).
- **Missing JSONB keys** → Models should tolerate missing keys in `jsonb_document` — use `dig` with defaults.
- **Duplicate project names** → Uniqueness validation with friendly error message.

---

### Architectural Context

These models form the **content layer** of agent-forge. Artifacts are the persistent documents that flow through the SDLC pipeline (Idea → Epic → PRD → Implementation). Tasks represent units of work sent to AiderDesk. Messages are the chat history within a task. All content is stored as JSONB for flexibility — the schema can evolve without migrations.

```
Project
├── Artifact (Epic)
│   ├── Artifact (PRD)
│   └── Artifact (PRD)
├── Task
│   ├── Message (user)
│   ├── Message (assistant)
│   └── Message (system)
└── Task
    └── Message (user)
```

---

### Acceptance Criteria

- [ ] All four models created with migrations.
- [ ] `bin/rails db:migrate` succeeds.
- [ ] `Project.create!(name: "test", project_dir: "projects/aider-desk-test")` works in console.
- [ ] `Artifact` hierarchy works: Epic with child PRDs, navigable via `parent`/`children`.
- [ ] All enums work: `artifact.draft?`, `artifact.approved!`, `task.in_progress?`.
- [ ] JSONB columns accept arbitrary hashes: `artifact.update!(jsonb_document: { sections: [...] })`.
- [ ] Seeds run without errors: `bin/rails db:seed`.
- [ ] Scopes work: `Artifact.by_type(:epic)`, `Artifact.roots`, `Message.ordered`.
- [ ] `project_dir` validation rejects paths outside `projects/`.
- [ ] All model tests pass with ≥ 90% coverage.

---

### Test Cases

#### Unit (Minitest)

- `test/models/project_test.rb`:
  - Valid with all required attributes.
  - Invalid without name, project_dir.
  - Invalid with duplicate name.
  - Invalid with project_dir outside `projects/`.
  - `has_many :artifacts` and `has_many :tasks` associations.

- `test/models/artifact_test.rb`:
  - Valid with required attributes.
  - Invalid without title, artifact_type, project.
  - Enum values work (draft, refined, approved, implemented, archived).
  - Parent/child hierarchy: Epic with PRD children.
  - Scopes: `by_type`, `by_status`, `roots`, `ordered`.
  - JSONB document stores and retrieves arbitrary data.

- `test/models/task_test.rb`:
  - Valid with required attributes.
  - Enum values work (pending, in_progress, completed, failed, timeout).
  - `has_many :messages` association.
  - JSONB metadata stores arbitrary data.

- `test/models/message_test.rb`:
  - Valid with required attributes.
  - Invalid without content, role, task.
  - Enum values work (user, assistant, system, tool).
  - `ordered` scope returns messages by created_at.

#### Integration (Minitest)

- N/A for this PRD (model-only).

---

### Manual Verification

1. Run `bin/rails db:migrate` — all migrations succeed.
2. Run `bin/rails db:seed` — sample data created.
3. Run `bin/rails console`:
   - `Project.count` → 1
   - `Artifact.count` → 3 (1 Epic + 2 PRDs)
   - `Task.count` → 1
   - `Message.count` → ≥ 2
   - `Artifact.roots.first.children.count` → 2
4. Verify enums: `Artifact.first.draft?` → true

**Expected**
- All models persist and query correctly.
- Hierarchy and associations work.
- JSONB columns accept flexible data.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: Do not run `db:drop` or `db:reset`. Use `db:migrate` only.
- Use string-backed enums (not integer) for readability in JSONB and API responses.
- Commit message suggestion: `"Implement PRD-002.2: Core data models (Project, Artifact, Task, Message)"`
