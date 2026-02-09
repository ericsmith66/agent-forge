# Feedback: Epic 001 – Bootstrap Aider Integration (V2)

**Source Document:** `knowledge_base/epics/epic-1-bootstrap/0000-overview-epic-001-aider-bootstrap.md`  
**Reviewer:** Junie  
**Date:** 2026-02-08

---

### Executive Summary

The Epic 001 draft provides a solid foundation for the Agent-Forge MVP. The choice of AiderDesk as a backend is strategic, and the separation into five distinct PRDs is logical. However, to truly "wow" and align with the `agent-forge` meta-framework standards, the documentation needs better adherence to the provided templates, clearer architectural boundaries, and more rigorous acceptance criteria.

---

### 1. Template Compliance & Structure

**Findings:**
- **Redundancy:** The document contains two versions of the Epic overview (one starting at line 1 and another at line 94). This creates confusion.
- **Missing Sections:** The draft misses several sections from the `0000-EPIC-OVERVIEW-template.md`, such as:
    - **Observability** (Rails.logger, Sentry, etc.)
    - **Key Guidance** details (Data Access, Accessibility, Mobile)
    - **Detailed PRDs link instructions.**
- **PRD Consolidation:** While the draft includes expanded PRDs at the end, the template suggests full PRD specifications should live in **separate files** (e.g., `PRD-1-01-setup.md`) once they are ready for implementation.

**Recommendation:**
- Use the first section purely for the **Overview** and move the detailed PRDs into their own files.
- Ensure all sections from the template are present, even if marked "N/A" for this specific epic.

---

### 2. Architectural Clarity

**Findings:**
- **SmartProxy vs. AiderDesk Client:** The relationship between the `AiderDesk::Client`, `AiderDeskAdapter`, and the `ai-agents` gem is described but could be more explicit regarding data flow.
- **Context Injection:** PRD-001.3 mentions "shared context injection" but doesn't specify *how* the `ai-agents` gem's shared context will be serialized for AiderDesk.

**Recommendation:**
- Add a brief "Data Flow" or "Handoff Sequence" diagram (Mermaid) to the Overview to visualize the `Coordinator -> Coder -> SmartProxy -> AiderDesk` path.

---

### 3. Safety & Constraints

**Findings:**
- **Non-Goals:** You've correctly identified "No auto-apply" as a non-goal.
- **Environment Isolation:** PRD-001.4 correctly specifies `projects/aider-desk-test` as the sandbox.

**Recommendation:**
- Strengthen the **Safety Rails** in PRD-001.2 and 01.3: explicitly require the `AiderDesk::Client` to enforce a `read_only` or `preview_only` flag unless a `FORCE_APPLY` constant is set (for testing).

---

### 4. Proposed Refined Epic (Merged & Optimized)

Below is a refined version of the Epic Overview, optimized for Agent-Forge standards.

```markdown
# Epic 001: Bootstrap Aider Integration as Coding Backend

**Epic Overview**
Integrate Aider (via the AiderDesk REST API on port 24337) as the primary coding backend for the `Coder` agent role. This epic establishes the "muscle" of the Agent-Forge framework, enabling reliable, safe code generation and diff production. Success means a Coordinator agent can hand off a task to a Coder agent, who then uses AiderDesk to propose file changes that the human user can review and accept in the GUI.

**User Capabilities**
- Invoke Aider-powered code edits via the Agent-Forge chat/dashboard.
- Preview side-by-side diffs of proposed changes before they are committed.
- Verify changes in an isolated sandbox (`projects/aider-desk-test`).
- Seamlessly transition from high-level planning to file-level implementation.

**Fit into Big Picture**
This is the "Execution Foundation." Without a robust coding backend, Agent-Forge remains a planner. By bootstrapping AiderDesk integration, we enable the framework to begin implementing its own features (dogfooding).

**Reference Documents**
- `knowledge_base/aider-desk/docs/aider-desk-py-docs.md`
- `knowledge_base/aider-desk/docs/rest-endpoints.md`
- `knowledge_base/ai-instructions/junie-log-requirement.md`

---

### Key Decisions Locked In

**Architecture / Boundaries**
- **Thin Wrapper Pattern:** The Ruby client (`lib/aider_desk/client.rb`) remains a thin JSON-over-HTTP wrapper. Business logic for "coding" stays in Aider; orchestration logic stays in Rails.
- **Sandboxing:** All integration testing and initial implementation tasks MUST happen inside `projects/`. The root `agent-forge` repo is protected by default.
- **Polling over WebSockets:** Use HTTP polling for task status to minimize initial complexity (deferred: ActionCable/WebSockets).

**UX / UI**
- **Dual-Pane Logic:** Chat/Logs on the left; Diffs/Preview on the right.
- **Human-in-the-Loop:** Every "Apply" action requires a manual click in the AiderDesk GUI or Agent-Forge dashboard.

**Testing**
- **VCR/Webmock:** Mandatory for all AiderDesk API tests to ensure CI can run without a live AiderDesk instance.

**Observability**
- **Task Logging:** All AiderDesk interactions are logged to `Rails.logger` and the `Junie Task Log` of the active task.

---

### High-Level Scope & Non-Goals

**In scope**
- Local AiderDesk setup verification and health checks.
- Autoloadable Ruby client and `bin/aider_cli`.
- `SmartProxy` adapter integrating with `ai-agents` gem tool calling.
- Bootstrap of `projects/aider-desk-test` sandbox.

**Non-goals / deferred**
- Real-time streaming of token-by-token output.
- Automated PR creation (Epic 2).
- RAG/Long-memory context injection (Epic 3).

---

### PRD Summary Table

| Priority | PRD Title | Scope | Dependencies | Suggested Branch |
|----------|-----------|-------|--------------|------------------|
| 01-01 | Local Setup | Verification, Ollama config, setup.md | None | `feat/aider-setup` |
| 01-02 | Client/CLI | `lib/aider_desk/client.rb`, credentials, `bin/aider_cli` | 01-01 | `feat/aider-client` |
| 01-03 | SmartProxy | `AiderDeskAdapter`, tool registration, handoff logic | 01-02 | `feat/aider-adapter` |
| 01-04 | Test Project | Bootstrap `projects/aider-desk-test` | None | `feat/aider-test-proj` |
| 01-05 | E2E & Docs | Full flow validation, integration.md, 90% coverage | 01-03, 01-04 | `feat/aider-e2e` |

---

### Key Guidance for All PRDs in This Epic

- **Architecture**: Always use the `AiderDeskAdapter` to wrap API calls. Never call the client directly from controllers or agents.
- **Data Access**: Ensure `project_dir` is always scoped to a folder inside `projects/` to prevent directory traversal.
- **Error Handling**: Gracefully handle `ConnectionRefused` and `Timeout`. Provide actionable advice (e.g., "Is AiderDesk running?").
- **Security**: Use `Rails.application.credentials` for AiderDesk Basic Auth.

---

### Success Metrics
- 100% pass rate for "Hello World" prompt -> file creation in test project.
- 90% Minitest coverage for `lib/aider_desk` and `SmartProxy` adapters.
- Zero "unintentional" file changes in the root repo during tests.

---

### Next Steps
1. Create `knowledge_base/epics/epic-1-bootstrap/0001-IMPLEMENTATION-STATUS.md`.
2. Break out PRD 01-01 into `PRD-1-01-local-setup-verification.md`.
```

---

### Final Feedback Note
This Epic is 90% there. By tightening the structure and moving PRDs to separate files, you ensure that agents (like me!) have a laser-focused context for each sub-task without being overwhelmed by the entire Epic's history. 🚀
