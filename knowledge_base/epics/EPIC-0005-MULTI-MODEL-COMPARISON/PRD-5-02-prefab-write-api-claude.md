#### PRD-5-02: Prefab Write API - Challenger (Claude/Aider)

**Log Requirements**
- AiderDesk: Ensure task logging is enabled.
- Capture:
    - Initial task load.
    - Implementation iterations.
    - Final compliance checklist.
    - Total execution time (from `onPromptFinished` metrics).

---

### Overview
This PRD defines the implementation phase for the Claude-3.5-Sonnet model via AiderDesk. Claude is tasked with implementing the EXACT same scope as PRD-5-01. The goal is to evaluate if Claude can maintain the same level of strict technical compliance as Junie when working on an isolated branch.

---

### Requirements

#### Functional
- Same as PRD-5-01.
- **Agent Selection:** Must use the `rails` parent agent with subagent delegation enabled.
- **Rule Injection:** Must load `.aider-desk/rules/epic-5-strict-directive.md` at the start of the task.

#### Non-Functional
- Same as PRD-5-01.
- **Comparison Focus:** Adherence to Open3 requirements vs. the "easy path" of backticks.

#### Rails / Implementation Notes
- Same as PRD-5-01.

---

### Acceptance Criteria
- [ ] Functional implementation matching PRD-5-01.
- [ ] ZERO usage of backticks (mandatory audit).
- [ ] Standardized RSpec tests included.
- [ ] All tests pass on the `epic-5/claude` branch.

---

### Architectural Context
Claude is often the most "creative" model; this test determines if that creativity leads to "Instruction Drift" when faced with rigid security constraints.

---

### Manual Verification
- Same as PRD-5-01.
- Additional Step: Compare the `request_id` implementation against Junie's (check for UUID consistency).

---

### Rollout / Deployment Notes
- Implementation must be committed to the `epic-5/claude` branch.
