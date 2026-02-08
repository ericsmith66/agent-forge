#### PRD-1-05: End-to-End Tests & Documentation

**PRD ID:** PRD-001.5  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-08  
**Branch:** `feat/aider-e2e`  
**Dependencies:** PRD-001.3, PRD-001.4

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-05-e2e-tests-docs-feedback-V{{N}}.md` in the same directory.

---

### Overview

Add comprehensive test coverage for the AiderDesk integration and update documentation in `knowledge_base/aider-desk/` to ensure maintainability and ease of use. This PRD ties together all previous PRDs by validating the full flow: prompt → adapter → AiderDesk → file change in test project. Target: 90% coverage on client and adapter code.

---

### Requirements

#### Functional

- Unit tests for client and adapter (mock HTTP with VCR/Webmock).
- Integration tests (VCR-recorded real API calls).
- System tests for CLI commands and handoff flow.
- Documentation in `knowledge_base/aider-desk/integration.md`:
  - Usage examples (Ruby client, CLI, adapter).
  - curl examples for common operations.
  - Troubleshooting guide.
  - Links to Epic/PRDs.
- Update `knowledge_base/aider-desk/setup.md` with any new findings.

#### Non-Functional

- 90% coverage measured with SimpleCov for `lib/aider_desk/` and `app/services/smart_proxy/`.
- Tests run in CI (GitHub Actions stub — `.github/workflows/test.yml`).
- Conform to `ai-agents` gem: tests for handoffs and tool calling.
- VCR cassettes stored in `test/fixtures/vcr_cassettes/aider_desk/`.

#### Rails / Implementation Notes

- `test/lib/aider_desk/client_test.rb` — unit tests.
- `test/services/smart_proxy/aider_desk_adapter_test.rb` — unit tests.
- `test/integration/aider_desk/` — integration tests.
- `test/fixtures/vcr_cassettes/aider_desk/` — recorded HTTP interactions.
- `knowledge_base/aider-desk/integration.md` — usage documentation.

---

### Error Scenarios & Fallbacks

- **VCR cassette missing** → Test fails with clear message. Document how to re-record.
- **AiderDesk not running during recording** → Document setup steps. Provide pre-recorded cassettes.
- **SimpleCov below 90%** → CI fails. Document which files need coverage.

---

### Architectural Context

This PRD is the validation layer for the entire Epic. It proves that all components (client, adapter, tool registration, test project) work together. The test suite serves as living documentation and regression protection. VCR cassettes ensure tests are reproducible without a live AiderDesk instance.

---

### Acceptance Criteria

- [ ] SimpleCov coverage ≥ 90% for `lib/aider_desk/` and `app/services/smart_proxy/`.
- [ ] End-to-end test: prompt → adapter → AiderDesk → file proposed in test project.
- [ ] CLI tests: `bin/aider_cli health`, `bin/aider_cli prompt:quick` pass.
- [ ] VCR cassettes committed for all integration tests.
- [ ] `knowledge_base/aider-desk/integration.md` committed with usage examples, curl examples, and troubleshooting.
- [ ] GitHub Actions workflow stub (`.github/workflows/test.yml`) committed.
- [ ] All tests pass: `bin/rails test` (green suite).
- [ ] All review artifacts (`*-feedback-V*.md`, `*-comments-V*.md`) archived or deleted before final commit.

---

### Test Cases

#### Unit (Minitest)

- `test/lib/aider_desk/client_test.rb`: All client methods, error handling, credential loading.
- `test/services/smart_proxy/aider_desk_adapter_test.rb`: Adapter methods, polling, timeout, project_dir validation.

#### Integration (Minitest)

- `test/integration/aider_desk/health_check_test.rb`: VCR-recorded health check.
- `test/integration/aider_desk/task_creation_test.rb`: VCR-recorded task creation + prompt.
- `test/integration/aider_desk/e2e_flow_test.rb`: Full flow — prompt → file change in test project.

#### System / Smoke (Capybara)

- `test/system/aider_cli_test.rb`: CLI commands execute and return expected output.

---

### Manual Verification

1. Run full test suite: `bin/rails test`
2. Verify all tests pass (green).
3. Check coverage: `open coverage/index.html` — verify ≥ 90% for target files.
4. Open `knowledge_base/aider-desk/integration.md` — verify it contains:
   - Ruby client usage examples.
   - CLI usage examples.
   - curl examples.
   - Troubleshooting section.
5. Run a manual end-to-end flow:
   - Start AiderDesk.
   - In Rails console: `SmartProxy::AiderDeskAdapter.new.run_prompt(nil, "Add a comment to hello.rb", "code", "projects/aider-desk-test")`
   - Verify diff returned and visible in AiderDesk GUI.

**Expected**
- All tests green.
- Coverage ≥ 90%.
- Documentation is complete and accurate.
- Manual E2E flow succeeds.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: Tests must not modify real projects. Use VCR for reproducible API calls.
- Claude for test code, Grok for edge cases, Ollama for local runs.
- Commit message suggestion: `"Implement PRD-001.5: AiderDesk tests & documentation"`
