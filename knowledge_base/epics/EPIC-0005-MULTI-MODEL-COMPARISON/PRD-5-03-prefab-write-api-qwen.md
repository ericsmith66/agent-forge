#### PRD-5-03: Prefab Write API - Challenger (Qwen/Ollama)

**Log Requirements**
- Ollama Prompt Runner (Ruby/Python): Capture the full console output, including the "Fix Loop" metrics and model warm-up times.
- Capture:
    - Failure classification (e.g., "Partial Response", "Ollama Error").
    - Stale-chunk detection events.
    - Total execution time.

---

### Overview
This PRD defines the implementation phase for the `qwen3-coder-next:latest` model via AiderDesk and Ollama. Qwen demonstrated 95% compliance in the initial spike when under the Strict Directive. This test will confirm if that performance is repeatable and if it can correctly bridge the "Deduplication Logic" gap that it missed in the first run.

---

### Requirements

#### Functional
- Same as PRD-5-01.
- **Deduplication Focus:** Must correctly implement the `recent_for` query in the `ControlEvents` model and use it in the controller/webhook logic.
- **Rule Injection:** Must load `.aider-desk/rules/epic-5-strict-directive.md` at the start of the task.

#### Non-Functional
- Same as PRD-5-01.
- **Resilience:** Evaluate Qwen's self-correction capabilities in the "Fix + rerun loop."

#### Rails / Implementation Notes
- Same as PRD-5-01.

---

### Acceptance Criteria
- [ ] Functional implementation matching PRD-5-01.
- [ ] ZERO usage of backticks (mandatory audit).
- [ ] Deduplication logic correctly skips echo events (verified by tests).
- [ ] All tests pass on the `epic-5/qwen` branch.

---

### Architectural Context
Qwen is our "Strict Compliance" specialist. This test verifies if its high compliance comes at the cost of significantly higher wall-clock time or if it can become more efficient.

---

### Manual Verification
- Same as PRD-5-01.
- Additional Step: Verify that the `ControlEvent` table has a composite index on `accessory_id` and `created_at` (as recommended in the config feedback).

---

### Rollout / Deployment Notes
- Implementation must be committed to the `epic-5/qwen` branch.
