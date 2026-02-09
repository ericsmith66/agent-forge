#### PRD-2-01: Rails App Scaffold & Core Configuration

**PRD ID:** PRD-002.1  
**Version:** 2.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-scaffold`  
**Dependencies:** Epic 1 (complete)

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-01-rails-scaffold-feedback-V{{N}}.md` in the same directory.

---

### Overview

Convert the agent-forge root directory from a plain Ruby project into a full Rails 8+ application. This is the single most impactful structural decision for Epic 2 — all subsequent UI PRDs depend on having a working Rails app with routing, asset pipeline, Hotwire (Turbo + Stimulus), ActionCable, and database connectivity.

**Why convert now (not later):**
- Avoids building UI on top of a mismatched foundation, which would create technical debt.
- Immediate access to full Rails MVC, routing, asset pipeline, Hotwire, ActionCable, ViewComponents, services, jobs.
- Simplifies deployment, testing, and developer onboarding.
- Aligns with the long-term goal of using Rails as the primary backend for agent-forge.

**Why full Rails (not `--api` mode):**
- We need ActionCable (WebSockets for real-time chat), views (4-pane dashboard), asset pipeline (Tailwind/DaisyUI), and Hotwire (Turbo Frames/Streams + Stimulus).
- API-only mode would require adding all of these back manually.

**Key constraint:** Existing code (`lib/aider_desk/`, `lib/tool_adapter/`, `bin/aider_cli`, `test/`, `knowledge_base/`, `.junie/`, `projects/`) must be preserved and remain functional after conversion.

---

### Requirements

#### Functional

- Rails 8 app at the project root with PostgreSQL, Tailwind CSS, Hotwire (Turbo + Stimulus), and importmap.
- DaisyUI installed via CDN link in `application.html.erb` (simplest approach; can switch to npm later).
- ViewComponent gem added to Gemfile.
- Devise gem added with a basic `User` model (email, password) — no full auth flow yet, just the model and migration.
- Root route (`/`) renders a minimal dashboard shell page (`DashboardController#show`) with a styled heading and DaisyUI button to confirm styling works.
- `bin/rails server` boots without errors on port 3000.
- `bin/rails console` loads and can access models.
- Existing `lib/aider_desk/client.rb` and `lib/tool_adapter/aider_desk_adapter.rb` remain loadable via `require` or Rails autoload.
- Existing `bin/aider_cli` continues to work as a standalone script (no Rails boot required).
- Existing tests in `test/` continue to pass (adapt `test_helper.rb` if needed for Rails test environment).

#### Non-Functional

- PostgreSQL databases: `agent_forge_development`, `agent_forge_test`.
- Tailwind CSS configured via Rails 8 default (`tailwindcss-rails` gem).
- Importmap for JavaScript (Rails 8 default — no webpack/esbuild).
- `knowledge_base/`, `.junie/`, `projects/` directories preserved **in place** (not moved into `app/` or `lib/`).
- `.gitignore` updated for Rails conventions (add `tmp/`, `log/`, `storage/`, `node_modules/` if not already present).
- Minitest remains the test framework (no RSpec).

---

### Exact `rails new` Command & Flags

```bash
rails new . \
  --database=postgresql \
  --css=tailwind \
  --skip-test \
  --skip-jbuilder \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage
```

**Flag rationale:**

| Flag | Reason |
|------|--------|
| `--database=postgresql` | Required for JSONB artifact storage, future RLS |
| `--css=tailwind` | DaisyUI builds on Tailwind; Rails 8 default integration |
| `--skip-test` | Preserve existing `test/` directory — do NOT overwrite |
| `--skip-jbuilder` | Not needed; we use Turbo Streams, not JSON APIs |
| `--skip-action-mailbox` | No email processing needed |
| `--skip-action-text` | Rich text not needed (we use JSONB + markdown) |
| `--skip-active-storage` | No file uploads in MVP |

**NOT skipped (we need these):**
- ActionCable — required for real-time chat (PRD-2-05)
- Hotwire/Turbo — required for Turbo Frames/Streams
- Stimulus — required for UI behavior controllers
- Active Record — required for models

---

### Folder Migration Plan

**Directories that stay in place (no move):**

| Directory | Action | Notes |
|-----------|--------|-------|
| `knowledge_base/` | Keep as-is | Not Rails code; reference docs for agents |
| `.junie/` | Keep as-is | Junie guidelines; not Rails config |
| `projects/` | Keep as-is | Independent git repos; already in `.gitignore` |
| `lib/aider_desk/` | Keep as-is | Add `lib/` to Rails autoload path |
| `lib/tool_adapter/` | Keep as-is | Add `lib/` to Rails autoload path |
| `test/` | Keep as-is | Adapt `test_helper.rb` for Rails; existing tests must pass |
| `bin/aider_cli` | Keep as-is | Standalone script; Rails adds `bin/rails`, `bin/setup`, etc. alongside it |
| `coverage/` | Keep as-is | Already in `.gitignore` |

**New directories created by Rails:**

| Directory | Purpose |
|-----------|---------|
| `app/` | Controllers, models, views, components, services |
| `config/` | Rails configuration, routes, database.yml, initializers |
| `db/` | Migrations, schema, seeds |
| `public/` | Static assets |
| `tmp/`, `log/`, `storage/` | Runtime directories (gitignored) |

**Conflict resolution strategy:**
- If `rails new .` prompts about overwriting existing files, **do not use `--force`**.
- Generate into a temp directory first (`rails new /tmp/agent-forge-scaffold ...`), then selectively copy Rails files into the project root.
- Alternatively, run `rails new .` and carefully review each conflict prompt, keeping existing files where they matter (`test/test_helper.rb`, `bin/aider_cli`, `.gitignore`).
- Use `git diff` after generation to verify no existing code was lost.

---

### Git History Preservation

- Prefer `git mv` where possible (not applicable here since we're adding new files, not moving existing ones).
- After `rails new .`, review `git status` carefully before committing.
- Ensure no existing files were deleted or overwritten.
- Commit the Rails scaffold as a single commit on the feature branch.

---

### Configuration Details

#### `config/application.rb` — Autoload `lib/`

```ruby
# Add lib/ to autoload paths so AiderDesk::Client and ToolAdapter work
config.autoload_paths << Rails.root.join("lib")
config.eager_load_paths << Rails.root.join("lib")
```

#### `config/database.yml`

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: agent_forge_development

test:
  <<: *default
  database: agent_forge_test

production:
  <<: *default
  database: agent_forge_production
  url: <%= ENV["DATABASE_URL"] %>
```

#### DaisyUI Setup

Add to `app/views/layouts/application.html.erb` `<head>`:

```html
<link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet" type="text/css" />
```

#### Gemfile Additions

```ruby
gem "view_component", "~> 3.0"
gem "devise", "~> 4.9"
gem "commonmarker", "~> 1.0"   # Markdown rendering for artifact viewer
```

#### Initializers (if needed)

- `config/initializers/aider_desk.rb` — optional; can configure default AiderDesk URL, credentials from Rails credentials.
- No Ollama or smart_proxy initializers needed yet (deferred to Epic 3+).

---

### `test/test_helper.rb` Adaptation

The existing `test_helper.rb` uses SimpleCov and loads `lib/` directly. After Rails conversion, it should be updated to optionally load the Rails environment:

```ruby
# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/knowledge_base/'
  add_filter '/projects/'

  add_group 'AiderDesk Client', 'lib/aider_desk'
  add_group 'ToolAdapter', 'lib/tool_adapter'

  minimum_coverage 90
  minimum_coverage_by_file 80
end

# Load Rails environment if available (for model/controller tests)
ENV["RAILS_ENV"] ||= "test"
begin
  require_relative "../config/environment"
  require "rails/test_help"
rescue LoadError
  # Rails not available — running standalone lib tests
end

require 'minitest/autorun'
require 'minitest/pride'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'aider_desk/client'
```

This allows:
- `ruby -Ilib:test test/run_all_tests.rb` — works without Rails (existing behavior)
- `bin/rails test` — works with Rails environment loaded

---

### Error Scenarios & Fallbacks

- **`rails new .` conflicts with existing files** → Generate into temp directory, then copy Rails files over. Preserve existing `lib/`, `test/`, `bin/aider_cli`, `knowledge_base/`, `.junie/`.
- **PostgreSQL not running** → Document requirement in README. Check with `pg_isready` before `db:create`.
- **Existing tests break after conversion** → Adapt `test/test_helper.rb` to conditionally load Rails environment. Ensure SimpleCov and existing test infrastructure still works.
- **DaisyUI CDN unavailable** → Fall back to Tailwind-only styling. DaisyUI is enhancement, not blocker.
- **`bin/aider_cli` breaks** → Ensure it does NOT require Rails boot. It uses `require_relative '../lib/aider_desk/client'` which should still work.
- **Devise migration fails** → Ensure PostgreSQL is running and databases are created first. Run `bin/rails db:create` before `bin/rails generate devise:install`.

---

### Architectural Context

This PRD converts agent-forge from a library-only project into a full Rails application. The existing `lib/` code (AiderDesk client, ToolAdapter) becomes part of the Rails autoload path. The `test/` directory transitions from standalone Minitest to Rails-integrated Minitest (with backward compatibility for standalone runs). This is a one-time structural change that enables all subsequent UI work.

```
Before:                          After:
├── lib/                         ├── app/
│   ├── aider_desk/              │   ├── controllers/
│   └── tool_adapter/            │   │   └── dashboard_controller.rb
├── test/                        │   ├── models/
├── bin/                         │   │   └── user.rb
│   └── aider_cli                │   ├── views/
├── knowledge_base/              │   │   ├── layouts/
└── projects/                    │   │   └── dashboard/show.html.erb
                                 │   └── components/  (empty, ready for PRD-2-03+)
                                 ├── config/
                                 │   ├── database.yml
                                 │   ├── routes.rb
                                 │   └── application.rb (autoloads lib/)
                                 ├── db/
                                 │   └── migrate/
                                 ├── lib/          (preserved)
                                 │   ├── aider_desk/
                                 │   └── tool_adapter/
                                 ├── test/         (preserved + adapted)
                                 ├── bin/          (rails + setup + aider_cli)
                                 ├── knowledge_base/ (preserved)
                                 ├── .junie/       (preserved)
                                 └── projects/     (preserved, gitignored)
```

---

### Acceptance Criteria

- [ ] `bin/rails server` starts on port 3000 without errors.
- [ ] `http://localhost:3000` renders the placeholder dashboard page with styled heading and DaisyUI button.
- [ ] `bin/rails console` loads; `User` model accessible (after migration).
- [ ] `bin/rails db:create` and `bin/rails db:migrate` run without errors.
- [ ] Existing `lib/aider_desk/client.rb` loadable in Rails console: `AiderDesk::Client.new` works.
- [ ] Existing `lib/tool_adapter/aider_desk_adapter.rb` loadable in Rails console: `ToolAdapter::AiderDeskAdapter.new` works.
- [ ] Existing `bin/aider_cli health --url http://localhost:24337 --user admin --pass booberry` still works (standalone, no Rails boot).
- [ ] Existing tests pass: `ruby -Ilib:test test/run_all_tests.rb` — 101 runs, 0 failures.
- [ ] Tailwind CSS classes render correctly on the dashboard page.
- [ ] DaisyUI classes available (e.g., `btn btn-primary` renders styled button on dashboard).
- [ ] ViewComponent installed: `ViewComponent::Base` accessible in Rails console.
- [ ] `knowledge_base/`, `.junie/`, `projects/` directories unchanged and untracked by git.
- [ ] No existing files deleted or overwritten (verify with `git diff`).

---

### Test Cases

#### Unit (Minitest)

- Existing `test/lib/aider_desk/client_test.rb` — must still pass.
- Existing `test/lib/aider_desk/client_webmock_test.rb` — must still pass.
- Existing `test/lib/tool_adapter/aider_desk_adapter_test.rb` — must still pass.
- `test/models/user_test.rb` — basic User model validation (email presence, uniqueness via Devise).

#### Integration (Minitest)

- `test/integration/dashboard_test.rb` — GET `/` returns 200, response body contains "Agent-Forge" and dashboard content.
- Existing `test/integration/aider_desk/` tests — must still pass.

#### System / Smoke

- Existing `test/system/aider_cli_test.rb` — CLI tests still pass.

---

### Manual Verification

1. Run `bin/rails server` — app starts on port 3000.
2. Open `http://localhost:3000` — see placeholder dashboard with styled heading and DaisyUI button.
3. Run `bin/rails console`:
   - Type `User` — no errors, model loads.
   - Type `AiderDesk::Client.new` — client instantiates.
   - Type `ToolAdapter::AiderDeskAdapter.new` — adapter instantiates.
4. Run `bin/rails db:migrate` — migrations succeed.
5. Run `bin/aider_cli health --url http://localhost:24337 --user admin --pass booberry` — still works.
6. Run `ruby -Ilib:test test/run_all_tests.rb` — all 101 existing tests pass.
7. Inspect `knowledge_base/`, `.junie/`, `projects/` — unchanged.
8. Run `git status` — no unexpected deletions or overwrites.

**Expected**
- Rails app boots and serves pages.
- Existing code and tests unaffected.
- Tailwind + DaisyUI styling visible on dashboard.
- All directories preserved.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- **Safety rails:**
  - Do NOT delete or overwrite existing `lib/`, `test/`, `bin/aider_cli`, `knowledge_base/`, `.junie/`, or `projects/` directories.
  - The `rails new .` command may prompt about overwriting files — handle conflicts carefully, preserving existing content.
  - Do NOT run `db:drop` or `db:reset` without confirmation.
  - Do NOT commit without explicit user approval.
- **Conflict strategy:** If `rails new .` would overwrite critical files, generate into `/tmp/agent-forge-scaffold` first, then selectively merge.
- **Verification order:** After scaffold: (1) `bin/rails server` boots, (2) existing tests pass, (3) `bin/aider_cli` works, (4) dashboard renders.
- Commit message suggestion: `"Implement PRD-002.1: Convert agent-forge root to Rails 8 app"`
