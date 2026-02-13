### Configuration Review & Refinement Feedback: `ror-agent-forge-config`

This document provides a detailed review of the `ror-agent-forge-config` directory copied from Epic-5 findings. It suggests specific changes to align with project guidelines and improve model compliance based on the PRD-5-01 retrospective.

---

#### 1. Strict Execution Directive (`rules/epic-5-strict-directive.md`)
**Observation:** The directive is highly effective but lacks "Negative Constraints" that specifically block observed failures from PRD-5-01 testing.

**Recommended Changes:**
- **Explicit Prohibition of Rails "Magic" in Critical Paths:** Add a rule: *"Do NOT use Rails system calls like `system()` or `%x` in any service that interacts with the Prefab API. Use `Open3` exclusively."*
- **Boolean Coercion Specifics:** The directive lists variants (1, "on", etc.) but doesn't mandate a **Helper Module**. 
    - *Suggestion:* Require implementation of `HomeKitCoercion` concern to centralize logic and prevent fragmented implementations across controllers.
- **Fail-Fast Clause:** Add: *"If a test fails 3 times consecutively, STOP and ask the user for a architectural review of the test strategy."* (Prevents the "Infinite Fix Loop" observed in Qwen).

---

#### 2. Hierarchical Agent Refinement (`agents/rails/`)
**Observation:** The parent agent (`config.json`) lacks explicit delegation triggers.

**Recommended Changes:**
- **Update `customInstructions`:** 
    - *From:* "Delegate specialized tasks to subagents when appropriate."
    - *To:* "Delegate to the `debug` subagent IMMEDIATELY if any test suite failure persists for more than 2 iterations. Delegate to `ui` for all ViewComponent and Tailwind styling tasks."
- **Shared Rule Injection:** Ensure the `rules/` directory in the parent agent contains a `global-rails-invariants.md` that is inherited by all sub-agents.

---

#### 3. Skill Pattern Hardening (`skills/`)
**Observation:** Skills are currently descriptive but not "Code-Snippet Ready" enough to prevent minor implementation drift.

**Recommended Changes:**
- **`rails-open3-safe-exec`:** Include a mandatory "Retry Wrapper" pattern in the example. PRD-5-01 requires 3 retries with 500ms sleep; this should be baked into the skill's example code.
- **`rails-webhook-dedupe`:** Add a requirement for **Index Check**. 
    - *New Rule:* "When implementing deduplication, ensure the `accessory_id` and `created_at` columns are covered by a composite index to maintain performance."

---

#### 4. Command Lifecycle Alignment (`commands/epic5/`)
**Observation:** Verification commands are currently too generic.

**Recommended Changes:**
- **Mandatory Audit Check:** Add a step in the `verify.md` template: *"Verify that the `audit_logs` table contains a unique `request_id` for every test run performed during verification."*
- **Open3 Audit:** Add a step: *"Run `grep -r "Open3" app/services` to ensure no illegal backticks or system calls were introduced in the implementation phase."*

---

#### 📝 Summary of Specific Recommendations for the Strict Directive
*Based on PRD-5-01 "Lessons Learned":*

1.  **Strict Typing:** Force `request_id` to be stored as a `uuid` type in PostgreSQL, not a string, to enforce data integrity.
2.  **Explicit Timeouts:** Every Open3 call MUST include a timeout (e.g., `timeout: 5.seconds`) to prevent zombie processes if the external API hangs.
3.  **Log Scrubbing:** Mandate that `request_payload` in logs does NOT contain sensitive API keys (use `[FILTERED]`).

---

**Next Action:** After user review, these refinements will be merged into the `ror-agent-forge-config` master library before the `bin/setup-aider-desk` script is finalized.
