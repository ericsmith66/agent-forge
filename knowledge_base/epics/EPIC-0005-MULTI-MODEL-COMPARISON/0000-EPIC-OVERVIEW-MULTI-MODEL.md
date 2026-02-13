**Epic 5: Multi-Model Performance Comparison**

**Epic Overview**
This epic focuses on a rigorous head-to-head comparison of three AI models—Junie (native), Claude-3.5-Sonnet (via AiderDesk), and Qwen3-Coder (via AiderDesk/Ollama)—implementing the same set of critical Rails infrastructure components. The goal is to evaluate each model's ability to adhere to a **STRICT EXECUTION DIRECTIVE**, maintain high security standards (Open3 usage), and produce production-grade Ruby on Rails code in an unattended or semi-unattended fashion.

The implementation will occur in the `eureka-homekit` project. Each model will work on its own dedicated branch to ensure total isolation and a clean baseline for comparison.

**User Capabilities**
- Transparent comparison of model performance on "Real World" complex Rails tasks.
- Standardized AiderDesk configuration environment that works consistently across local and remote models.
- Reusable "Strict Execution Directive" pattern that significantly reduces model drift and technical debt.

**Fit into Big Picture**
This epic validates the "Agent-Forge" meta-framework's ability to orchestrate and evaluate different intelligence providers. The findings will directly inform the future default model selection and prompting strategies for the entire Rails project family.

**Reference Documents**
- `knowledge_base/epics/epic-3-spike-aider-desk/findings/aider_desk_config_plan.md`
- `knowledge_base/epics/epic-3-spike-aider-desk/findings/llm_and_config_observations.md`
- `knowledge_base/epics/epic-3-spike-aider-desk/findings/config_refinement_feedback.md`
- `knowledge_base/epics/epic-3-spike-aider-desk/findings/epic-5/ror-agent-forge-config/rules/epic-5-strict-directive.md`

---

### Key Decisions Locked In

**Architecture / Boundaries**
- **Isolation:** Models MUST work on separate branches (`epic-5/junie`, `epic-5/claude`, `epic-5/qwen`).
- **Standardization:** All models must use the same `ror-agent-forge-config` shared library.
- **Project Scope:** Implementation is restricted to `projects/eureka-homekit`.

**Testing**
- **Strict Mandate:** 100% RSpec/Minitest coverage for all new services and controllers.
- **Safety:** Mock external API calls unless explicitly testing live connectivity in controlled environments.

**Observability**
- **Task Logs:** Mandatory Junie/AiderDesk logs for every PRD implementation.
- **Audit Logs:** Database-level audit logging for all Prefab API interactions (UUIDs, latency, source).

---

### High-Level Scope & Non-Goals

**In scope**
- Refining the general RoR config into project-specific standards.
- Developing the `bin/setup-aider-desk` automation.
- Full implementation of the Prefab Write API by Junie (Control).
- Parallel implementations by Claude and Qwen.
- Detailed metrics gathering and synthesis.

**Non-goals / deferred**
- Cross-pollinating code between model branches.
- Modifying the core Agent-Forge dashboard (deferred to Epic 6).

---

### PRD Summary Table

| Priority | PRD Title | Scope | Dependencies | Suggested Branch | Notes |
|----------|-----------|-------|--------------|------------------|-------|
| 5-00 | Config & Environment Standardization | Refine shared configs + `bin/setup-aider-desk` | None | `main` | Foundation for all testing |
| 5-01 | Prefab Write API - Control (Junie) | Implement full Prefab API service + audit logging | 5-00 | `epic-5/junie` | The baseline |
| 5-02 | Prefab Write API - Challenger (Claude) | Same scope as 5-01 via AiderDesk/Claude | 5-00 | `epic-5/claude` | Comparison point |
| 5-03 | Prefab Write API - Challenger (Qwen) | Same scope as 5-01 via AiderDesk/Qwen | 5-00 | `epic-5/qwen` | Comparison point |
| 5-04 | Comparison & Synthesis | Consolidate metrics and update guidelines | 5-01, 5-02, 5-03 | `main` | Final report |

---

### Key Guidance for All PRDs in This Epic

- **Architecture**: Follow the "Open3-only" and "UUID Audit" patterns established in the Strict Directive.
- **Data Access**: Ensure all database interactions for auditing and deduplication are indexed and efficient.
- **Error Handling**: Implement a 3-attempt fixed-sleep retry policy for external API calls.
- **Security**: Zero tolerance for backticks (`) or shell system calls.

---

### Success Metrics

- **Code Quality:** Measured by adherence to Rails conventions and DRY principles.
- **Instruction Compliance:** 100% adherence to the "Strict Execution Directive."
- **Execution Time:** Wall-clock time from task start to verification.
- **Security Compliance:** Automated check for backticks and unsafe shell usage.

---

### Estimated Timeline

- PRD 5-00: 1-2 sessions
- PRD 5-01: 2-3 sessions
- PRD 5-02: 2-3 sessions
- PRD 5-03: 2-3 sessions
- PRD 5-04: 1 session

---

### Next Steps

1. Create `knowledge_base/epics/EPIC-0005-MULTI-MODEL-COMPARISON/` directory.
2. Initialize implementation status tracker.
3. Proceed with PRD 5-00 (Environment Standardization).
