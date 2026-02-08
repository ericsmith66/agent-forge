#### PRD-1-03: SmartProxy Adapter & ai-agents Tool Integration

**PRD ID:** PRD-001.3  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-08  
**Branch:** `feat/aider-adapter`  
**Dependencies:** PRD-001.2

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-03-smartproxy-adapter-feedback-V{{N}}.md` in the same directory.

---

### Overview

Extend SmartProxy with an AiderDesk backend/adapter and register it as a tool in the `ai-agents` gem, allowing the Coordinator to hand off coding tasks to the Coder role using AiderDesk for execution. The adapter wraps the Ruby client (PRD-001.2) and enforces safety (preview-only, no auto-apply). Shared context from the `ai-agents` gem is serialized as additional prompt text before calling AiderDesk (full RAG injection deferred to Epic 3).

---

### Requirements

#### Functional

- `SmartProxy::AiderDeskAdapter` in `app/services/smart_proxy/aider_desk_adapter.rb`.
- Implements `#run_prompt(task_id, prompt, mode, project_dir)` with polling.
- Register as `ai-agents` tool (define schema for tool calling: `prompt`, `mode`, `project_dir`).
- Coordinator handoff: `/implement <prd-id>` → Coder tool call to AiderDesk.
- Return diffs, status, messages for UI preview (right pane).
- Shared context injection: prepend `ai-agents` shared context as additional prompt text.

#### Non-Functional

- Polling timeout configurable (default `120s`).
- Log all calls/responses to `Rails.logger`.
- Conform to `ai-agents` gem: use shared context injection in tool calls.
- Safety: No auto-apply — return preview diffs only. `preview_only: true` enforced.
- `project_dir` must be scoped to `projects/` — reject any path outside. Validate with:
  ```ruby
  Pathname.new(project_dir).cleanpath.to_s.start_with?(Rails.root.join("projects").to_s)
  ```

#### Rails / Implementation Notes

- `app/services/smart_proxy/aider_desk_adapter.rb` — adapter class.
- `app/services/smart_proxy/base_adapter.rb` — base class (if not already present).
- Tool registration in `config/initializers/ai_agents.rb` or equivalent.
- Routes: N/A (tool is invoked programmatically via ai-agents).

---

### Error Scenarios & Fallbacks

- **AiderDesk unreachable** → Return `{ status: :error, message: "AiderDesk not running" }`. Log to `Rails.logger.error`.
- **Polling timeout** → Return partial result with `status: :timeout` and any messages received so far.
- **Invalid project_dir** → Raise `ArgumentError` if path is outside `projects/`.
- **Tool call schema mismatch** → Log warning, return descriptive error to Coordinator.

---

### Architectural Context

The adapter sits between the `ai-agents` gem's tool-calling mechanism and the AiderDesk REST API. It follows the Adapter pattern so backends can be swapped later (e.g., direct Aider CLI, GitHub Copilot). The Coordinator agent never touches AiderDesk directly — it hands off to the Coder agent, which invokes the adapter as a registered tool.

```
Coordinator → Coder (ai-agents handoff) → AiderDeskAdapter → AiderDesk::Client → REST API
```

---

### Acceptance Criteria

- [ ] `SmartProxy::AiderDeskAdapter` instantiates and passes health check.
- [ ] `ai-agents` tool call succeeds: prompt → AiderDesk → diffs returned.
- [ ] `/implement` command in chat → handoff → task created in AiderDesk.
- [ ] Diffs displayed in right pane without errors.
- [ ] `project_dir` validation rejects paths outside `projects/`.
- [ ] All interactions logged to `Rails.logger`.
- [ ] No auto-apply — diffs returned for preview only.

---

### Test Cases

#### Unit (Minitest)

- `test/services/smart_proxy/aider_desk_adapter_test.rb`: Test `run_prompt`, polling, timeout, error handling (mocked client).
- `test/services/smart_proxy/aider_desk_adapter_test.rb`: Test `project_dir` validation (rejects `../`, absolute paths outside projects/).

#### Integration (Minitest)

- `test/integration/smart_proxy/aider_desk_adapter_integration_test.rb`: Test full flow with VCR-recorded AiderDesk responses.

#### System / Smoke (Capybara)

- N/A for this PRD (UI integration deferred).

---

### Manual Verification

1. Open Rails console: `bin/rails console`
2. Run: `adapter = SmartProxy::AiderDeskAdapter.new`
3. Run: `adapter.run_prompt(nil, "Create hello.rb", "code", "projects/aider-desk-test")`
4. Verify: Returns hash with `status`, `diffs`, `messages`.
5. Verify: Task visible in AiderDesk GUI.
6. Verify: No files auto-applied.

**Expected**
- Adapter returns structured result with diffs.
- Task appears in AiderDesk GUI.
- No files modified without human approval.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Safety rails: Never apply edits or commit; preview only. `preview_only: true` enforced at adapter level.
- Use `ai-agents` gem for tool calling and handoffs; ensure 128k context support. Claude for adapter code, Grok for tool schema reasoning, Ollama for local handoff tests.
- Commit message suggestion: `"Implement PRD-001.3: SmartProxy adapter & ai-agents tool for AiderDesk"`
