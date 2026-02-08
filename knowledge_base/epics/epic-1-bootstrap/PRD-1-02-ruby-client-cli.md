#### PRD-1-02: Ruby Client & CLI Refinement

**PRD ID:** PRD-001.2  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-08  
**Branch:** `feat/aider-client`  
**Dependencies:** PRD-001.1

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-02-ruby-client-cli-feedback-V{{N}}.md` in the same directory.

---

### Overview

Refine the existing AiderDesk Ruby client library and CLI script to conform to Rails conventions, making them autoloadable, configurable via encrypted credentials, and ready for integration with SmartProxy and the `ai-agents` gem. The client defaults to `preview_only: true` — no edits are applied without explicit human action.

---

### Requirements

#### Functional

- Move library to `lib/aider_desk/client.rb` (autoloadable via Rails).
- Move CLI to `bin/aider_cli` (executable with shebang `#!/usr/bin/env ruby`).
- Config from `Rails.application.credentials.dig(:aider_desk)` — keys: `url`, `username`, `password`, `default_project_dir`.
- Enhance library with async polling: `run_prompt_and_wait` yields messages for streaming/logging.
- CLI supports all key commands: `health`, `settings`, `prompt:quick`, `task:create`, `task:status`, `task:messages`.
- Add convenience methods: `create_task_and_get_id`, `run_and_wait` with block.
- Client defaults to `preview_only: true`. No apply without explicit call.
- `FORCE_APPLY` constant (default `false`) for testing only.

#### Non-Functional

- Use `Rails.logger` for logging (configurable level).
- Raise `AiderDesk::ApiError` on failure if `raise_on_error: true` (default `false`).
- Timeouts configurable: read `300s`, open `30s`.
- Thread-safe (no global state).
- Conform to `ai-agents` gem: treat client calls as tool executions with shared context.

#### Rails / Implementation Notes

- `lib/aider_desk/client.rb` — main client class.
- `lib/aider_desk/api_error.rb` — custom error class.
- `bin/aider_cli` — CLI entry point.
- Add `config/credentials/aider_desk.yml.enc` entries (or use master credentials).

---

### Error Scenarios & Fallbacks

- **Connection refused** → Raise `AiderDesk::ConnectionError` with message: "AiderDesk not running on #{url}. Start the desktop app."
- **Auth failure (401)** → Raise `AiderDesk::AuthError` with message: "Invalid credentials. Check Rails credentials."
- **Timeout (polling)** → Return partial result with `status: :timeout` after configurable timeout.
- **Invalid JSON response** → Log warning, return raw response body for debugging.

---

### Architectural Context

The Ruby client is a **thin wrapper** — it translates Ruby method calls into HTTP requests to AiderDesk. No business logic lives here. The `SmartProxy::AiderDeskAdapter` (PRD-001.3) will consume this client. Controllers and agents should never call the client directly.

---

### Acceptance Criteria

- [ ] `lib/aider_desk/client.rb` loads in Rails console without errors.
- [ ] Client uses `Rails.application.credentials` automatically.
- [ ] `run_prompt_and_wait` polls and yields messages (test with block).
- [ ] `bin/aider_cli health` → OK response.
- [ ] `bin/aider_cli prompt:quick "test"` → task created, prompt sent, polled response.
- [ ] `preview_only: true` is the default — no apply without explicit override.
- [ ] All methods log to `Rails.logger`.
- [ ] Thread-safety: no class-level mutable state.

---

### Test Cases

#### Unit (Minitest)

- `test/lib/aider_desk/client_test.rb`: Test initialization, credential loading, method signatures, error handling (mocked HTTP).
- `test/lib/aider_desk/api_error_test.rb`: Test custom error classes.

#### Integration (Minitest)

- `test/integration/aider_desk/client_integration_test.rb`: Test against live AiderDesk (VCR-recorded). Health check, task creation, prompt execution.

#### System / Smoke (Capybara)

- N/A for this PRD.

---

### Manual Verification

1. Open Rails console: `bin/rails console`
2. Run: `client = AiderDesk::Client.new`
3. Verify: `client.health` returns 200 OK hash.
4. Run: `client.create_task(project_dir: "projects/aider-desk-test")` — returns task ID.
5. Run CLI: `bin/aider_cli health` — prints OK.
6. Run CLI: `bin/aider_cli prompt:quick "Create a hello.rb file"` — task created, response printed.

**Expected**
- All commands succeed without errors.
- No files are auto-applied (preview only).
- Logs appear in Rails logger output.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: No auto-commits or file changes; always preview. `preview_only: true` by default.
- Use `ai-agents` gem for multi-agent testing (e.g., handoff from Coordinator). Claude for code refinement, Grok for API error handling reasoning, Ollama for local CLI tests.
- Commit message suggestion: `"Implement PRD-001.2: Refine AiderDesk Ruby client and CLI"`
- If blocked (e.g., API change): update status tracker and suggest fallback test.
