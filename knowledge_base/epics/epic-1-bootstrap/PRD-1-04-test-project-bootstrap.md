#### PRD-1-04: Dedicated AiderDesk Test Project Bootstrap

**PRD ID:** PRD-001.4  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-08  
**Branch:** `feat/aider-test-proj`  
**Dependencies:** None

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-04-test-project-bootstrap-feedback-V{{N}}.md` in the same directory.

---

### Overview

Bootstrap a minimal Rails test project under `projects/aider-desk-test` to validate AiderDesk integration end-to-end. This sandbox is used for all AiderDesk API calls and integration tests, keeping the root `agent-forge` repo safe from unintended modifications. The test project mimics a simple Rails app (similar to eureka-homekit) with a webhook endpoint and model.

---

### Requirements

#### Functional

- Folder: `projects/aider-desk-test` with `git init` + initial commit.
- Minimal Rails 8 setup: PostgreSQL, Tailwind, Hotwire, ViewComponent.
- Simple webhook endpoint and model (`TestEvent`) to mimic eureka-homekit patterns.
- Use for all AiderDesk tests: send prompt → assert file change proposed.
- Project has its own `.gitignore` (standard Rails ignores).

#### Non-Functional

- Git init on creation; no nested repos in agent-forge root.
- Conform to `ai-agents` gem: test multi-agent flow (Planner → Coder with AiderDesk tool).
- Isolated from main repo (listed in root `.gitignore` via `projects/*`).
- No push to remote unless explicitly requested.

#### Rails / Implementation Notes

- `projects/aider-desk-test/` — independent Rails app.
- `projects/aider-desk-test/app/models/test_event.rb` — simple model.
- `projects/aider-desk-test/app/controllers/webhooks_controller.rb` — simple endpoint.
- `projects/aider-desk-test/db/migrate/..._create_test_events.rb` — migration.

---

### Error Scenarios & Fallbacks

- **Rails new fails** → Check Ruby/Rails version. Document required versions in setup.md.
- **PostgreSQL not running** → Use SQLite as fallback for test project only.
- **Git init conflict** → Verify `projects/` is in root `.gitignore`. Never nest git repos.

---

### Architectural Context

This test project is a **disposable sandbox**. It exists solely to validate that AiderDesk can receive prompts and propose file changes in a real Rails project. It is not part of agent-forge's codebase — it's an independent git repo under `projects/`. All integration tests in PRD-001.5 target this project.

---

### Acceptance Criteria

- [ ] `projects/aider-desk-test/` folder created with its own `.git/` directory.
- [ ] Rails app runs locally (`bin/rails server` starts without errors).
- [ ] `TestEvent` model exists with migration.
- [ ] Webhook endpoint responds to POST requests.
- [ ] Test prompt via AiderDesk → file change proposed in GUI → accept → files updated.
- [ ] Project is in root `.gitignore` (`projects/*`).
- [ ] No files from test project tracked by agent-forge root repo.

---

### Test Cases

#### Unit (Minitest)

- `projects/aider-desk-test/test/models/test_event_test.rb`: Basic model validation.

#### Integration (Minitest)

- `test/integration/aider_desk/test_project_integration_test.rb` (in agent-forge): Verify prompt → file creation in test project via AiderDesk adapter.

#### System / Smoke (Capybara)

- N/A for this PRD.

---

### Manual Verification

1. Navigate to `projects/aider-desk-test/`.
2. Run `bin/rails server` — app starts on port 3001 (or available port).
3. Run `bin/rails db:migrate` — migrations succeed.
4. In AiderDesk GUI, open the test project directory.
5. Send prompt: "Add a `status` column to TestEvent model."
6. Verify: AiderDesk proposes a migration file and model change.
7. Accept in GUI → files updated in `projects/aider-desk-test/`.

**Expected**
- Rails app runs without errors.
- AiderDesk proposes correct file changes.
- Files updated only after manual acceptance.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: No push to remote; local only. Follow git sub-project rules from guidelines.
- Use AiderDesk for code gen in the test project. Claude for Rails setup, Grok for test planning, Ollama for local validation.
- Commit message suggestion: `"Implement PRD-001.4: Bootstrap AiderDesk test project"`
- Remember: `git init` inside `projects/aider-desk-test/`, NOT in agent-forge root.
