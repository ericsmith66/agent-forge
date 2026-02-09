#### PRD-1-01: AiderDesk Local Setup & Verification

**PRD ID:** PRD-001.1  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-08  
**Branch:** `feat/aider-setup`  
**Dependencies:** None

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-01-local-setup-verification-feedback-V{{N}}.md` in the same directory.

---

### Overview

Verify and document the local AiderDesk instance to ensure agent-forge can reliably call its REST API for code generation. This includes port confirmation, auth setup, Ollama model configuration, and basic curl tests to prove end-to-end connectivity. This is the foundation PRD — nothing else works until AiderDesk is confirmed running and accessible.

---

### Requirements

#### Functional

- AiderDesk desktop app running locally with REST API on `http://localhost:24337`.
- Basic Auth tested and working (credentials from `Rails.application.credentials.dig(:aider_desk)` — never hardcode).
- Ollama provider set up with models pulled and configured:
  - Primary: `qwen2.5-coder:32b-instruct`
  - Fallback: `llama3.1:405b`
- Health check via curl succeeds (200 OK + JSON).
- Test prompt via curl creates a task visible in AiderDesk GUI.
- Documentation in `knowledge_base/aider-desk/setup.md` with exact setup steps, model pull commands, and troubleshooting.

#### Non-Functional

- API calls must be safe and non-destructive (no auto-commits).
- All tests must use Ollama for local execution.
- Documentation must include links to existing work (e.g., SmartProxy in nextgen-plaid repo).

#### Rails / Implementation Notes

- No Rails code changes in this PRD — purely verification and documentation.
- Credentials will be stored in Rails encrypted credentials in PRD-001.2.

---

### Error Scenarios & Fallbacks

- **AiderDesk not running** → Clear error message: "Connection refused on port 24337. Start AiderDesk desktop app."
- **Auth failure (401)** → Verify credentials in AiderDesk settings. Document correct Basic Auth format.
- **Ollama model not loaded** → Document `ollama pull` commands. Verify with `ollama list`.
- **Port conflict** → Document how to change port in AiderDesk settings.

---

### Architectural Context

This PRD is purely about environment verification. No application code is written. It establishes the prerequisite for all subsequent PRDs (01-02 through 01-05). The AiderDesk instance is treated as an external service that agent-forge consumes via REST.

---

### Acceptance Criteria

- [ ] `curl -u <AIDER_USER>:<AIDER_PASS> http://localhost:24337/api/settings` → 200 OK + JSON response. *(See `Rails.application.credentials.dig(:aider_desk)` for actual values.)*
- [ ] Test prompt via curl → task created and visible in AiderDesk GUI.
- [ ] Ollama model loads: test prompt in GUI uses `qwen2.5-coder:32b-instruct`.
- [ ] `knowledge_base/aider-desk/setup.md` committed with setup steps, Ollama pull commands, and troubleshooting.
- [ ] No errors in AiderDesk logs during tests.

---

### Test Cases

#### Unit (Minitest)

- N/A — no application code in this PRD.

#### Integration (Minitest)

- N/A — manual curl verification only.

#### System / Smoke (Capybara)

- N/A.

---

### Manual Verification

1. Start AiderDesk desktop app.
2. Verify it's listening: `curl -s http://localhost:24337/api/settings | head -c 200`
3. Test with auth: `curl -u <AIDER_USER>:<AIDER_PASS> http://localhost:24337/api/settings` *(Use credentials from `Rails.application.credentials.dig(:aider_desk)`.)*
4. Verify Ollama is running: `ollama list` (should show `qwen2.5-coder:32b-instruct`).
5. Send a test prompt via curl:
   ```bash
   curl -u <AIDER_USER>:<AIDER_PASS> -X POST http://localhost:24337/api/tasks \
     -H "Content-Type: application/json" \
     -d '{"projectDir": "/path/to/projects/aider-desk-test"}'
   ```
6. Verify task appears in AiderDesk GUI.

**Expected**
- All curl commands return 200 OK with valid JSON.
- Task is visible in AiderDesk GUI.
- No errors in AiderDesk logs.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: Do not apply any code changes during tests — preview only.
- Use Ollama (`qwen2.5-coder:32b-instruct`) for local testing. Claude for documentation writing, Grok for troubleshooting reasoning.
- Commit message suggestion: `"Implement PRD-001.1: AiderDesk local setup and verification"`
- If blocked (e.g., port conflict): log in status tracker and suggest human resolution.
