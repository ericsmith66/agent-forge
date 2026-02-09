# Epic 001 – Testing Strategy

**Epic:** Bootstrap Aider Integration as Coding Backend  
**Date:** 2026-02-08  
**Test Framework:** Minitest (no RSpec)

---

## Overview

This document defines the manual and automated testing strategy for Epic 001. The goal is to ensure that every component of the AiderDesk integration is verified — from basic connectivity to full end-to-end agent handoff flows. All automated tests use **Minitest**. HTTP interactions are recorded with **VCR** and stubbed with **Webmock** for CI reproducibility.

---

## Test Environments

| Environment | Purpose | AiderDesk Required? |
|-------------|---------|---------------------|
| **Unit** | Test individual classes in isolation (mocked HTTP) | No |
| **Integration** | Test component interactions with VCR-recorded responses | No (uses cassettes) |
| **Integration (live)** | Record new VCR cassettes against real AiderDesk | Yes |
| **System/Smoke** | Test CLI and end-to-end flows | Yes (for recording) |
| **Manual** | Human verification of GUI interactions | Yes |

---

## Automated Tests

### 1. Unit Tests (Mocked — no AiderDesk needed)

| Test File | What It Covers | PRD |
|-----------|---------------|-----|
| `test/lib/aider_desk/client_test.rb` | Client initialization, credential loading, method signatures, error classes, `preview_only` default, thread safety | 01-02 |
| `test/lib/aider_desk/api_error_test.rb` | Custom error classes (`ApiError`, `ConnectionError`, `AuthError`) | 01-02 |
| `test/services/smart_proxy/aider_desk_adapter_test.rb` | Adapter `run_prompt`, polling logic, timeout handling, `project_dir` validation (rejects paths outside `projects/`) | 01-03 |

**How to run:**
```bash
bin/rails test test/lib/aider_desk/
bin/rails test test/services/smart_proxy/
```

### 2. Integration Tests (VCR-recorded)

| Test File | What It Covers | PRD |
|-----------|---------------|-----|
| `test/integration/aider_desk/health_check_test.rb` | Health check returns 200 OK with valid JSON | 01-01 |
| `test/integration/aider_desk/task_creation_test.rb` | Task creation + prompt submission + polling | 01-02 |
| `test/integration/aider_desk/adapter_integration_test.rb` | Full adapter flow: prompt → AiderDesk → diffs returned | 01-03 |
| `test/integration/aider_desk/e2e_flow_test.rb` | End-to-end: prompt → file change proposed in test project | 01-05 |
| `test/integration/aider_desk/test_project_integration_test.rb` | Verify test project exists and accepts AiderDesk tasks | 01-04 |

**VCR cassettes location:** `test/fixtures/vcr_cassettes/aider_desk/`

**How to run:**
```bash
bin/rails test test/integration/aider_desk/
```

**How to re-record cassettes:**
1. Start AiderDesk desktop app (port 24337).
2. Delete the cassette file you want to re-record.
3. Run the specific test: `bin/rails test test/integration/aider_desk/health_check_test.rb`
4. VCR will record the new cassette automatically.

### 3. System / Smoke Tests

| Test File | What It Covers | PRD |
|-----------|---------------|-----|
| `test/system/aider_cli_test.rb` | CLI commands: `health`, `prompt:quick`, `task:create` | 01-02, 01-05 |

**How to run:**
```bash
bin/rails test test/system/aider_cli_test.rb
```

### 4. Coverage Target

- **Tool:** SimpleCov
- **Target:** ≥ 90% for:
  - `lib/aider_desk/` (client, errors)
  - `app/services/smart_proxy/` (adapter)
- **How to check:** `open coverage/index.html` after running tests.

---

## Manual Tests

### MT-01: AiderDesk Health Check (PRD 01-01)

**Preconditions:** AiderDesk desktop app running.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `curl http://localhost:24337/api/settings` | Connection succeeds (may return 401) |
| 2 | Run `curl -u <AIDER_USER>:<AIDER_PASS> http://localhost:24337/api/settings` | 200 OK + JSON response with settings. *(Use credentials from `Rails.application.credentials.dig(:aider_desk)`.)*  |
| 3 | Check AiderDesk logs | No errors |

### MT-02: Ollama Model Verification (PRD 01-01)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `ollama list` | Shows `qwen2.5-coder:32b-instruct` |
| 2 | In AiderDesk GUI, send a test prompt | Response uses the configured Ollama model |
| 3 | Check response quality | Coherent code output |

### MT-03: Ruby Client in Rails Console (PRD 01-02)

**Preconditions:** AiderDesk running, Rails app booted.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `bin/rails console` | Console starts |
| 2 | `client = AiderDesk::Client.new` | No errors, credentials loaded |
| 3 | `client.health` | Returns hash with 200 status |
| 4 | `client.create_task(project_dir: "projects/aider-desk-test")` | Returns task ID string |
| 5 | Verify `client.preview_only?` | Returns `true` |

### MT-04: CLI Commands (PRD 01-02)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `bin/aider_cli health` | Prints "OK" or JSON health response |
| 2 | `bin/aider_cli settings` | Prints AiderDesk settings JSON |
| 3 | `bin/aider_cli prompt:quick "Create hello.rb"` | Task created, prompt sent, response printed |

### MT-05: Adapter Handoff (PRD 01-03)

**Preconditions:** AiderDesk running, test project exists.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `bin/rails console` | Console starts |
| 2 | `adapter = SmartProxy::AiderDeskAdapter.new` | No errors |
| 3 | `result = adapter.run_prompt(nil, "Create hello.rb with puts 'hello'", "code", "projects/aider-desk-test")` | Returns hash with `status`, `diffs`, `messages` |
| 4 | Check AiderDesk GUI | Task visible, diff proposed |
| 5 | Verify no files auto-applied | Files unchanged until manual accept |

### MT-06: Test Project Validation (PRD 01-04)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `cd projects/aider-desk-test && ls -la .git` | `.git/` directory exists |
| 2 | `bin/rails server -p 3001` | Minimal Rails 8 app starts without errors |
| 3 | `bin/rails db:migrate` | Migrations succeed (TestEvent model) |
| 4 | `curl -X POST http://localhost:3001/webhooks` | Webhook endpoint responds |

### MT-07: Full End-to-End Flow (PRD 01-05)

**Preconditions:** AiderDesk running, test project exists, all PRDs implemented.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | In Rails console: send prompt via adapter targeting test project | Adapter returns diffs |
| 2 | In AiderDesk GUI: review proposed changes | Diff is visible and correct |
| 3 | Accept changes in GUI | Files updated in `projects/aider-desk-test/` |
| 4 | Verify file changes | New/modified files match the prompt intent |
| 5 | Run `bin/rails test` in agent-forge | All tests green |
| 6 | Check SimpleCov | ≥ 90% coverage |

---

## Test Data & Fixtures

| Item | Location | Purpose |
|------|----------|---------|
| VCR cassettes | `test/fixtures/vcr_cassettes/aider_desk/` | Recorded HTTP interactions for CI |
| Test project | `projects/aider-desk-test/` | Sandbox for integration tests |
| Credentials | `config/credentials.yml.enc` | AiderDesk auth (encrypted) |

---

## CI Pipeline (Stub)

A GitHub Actions workflow stub will be created at `.github/workflows/test.yml`:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bin/rails db:prepare RAILS_ENV=test
      - run: bin/rails test
```

**Note:** CI runs with VCR cassettes only (no live AiderDesk). Live integration tests are run locally during development/recording.

---

## Safety Checklist

Before marking any test as passing:

- [ ] No files were auto-applied without human confirmation.
- [ ] No git commits were made without explicit approval.
- [ ] All tests ran against `projects/aider-desk-test/` (not root repo).
- [ ] No credentials or secrets appear in test output or cassettes.
- [ ] VCR cassettes are sanitized (no real auth tokens recorded).
- [ ] No hardcoded credentials in any document — use `Rails.application.credentials.dig(:aider_desk)`.
