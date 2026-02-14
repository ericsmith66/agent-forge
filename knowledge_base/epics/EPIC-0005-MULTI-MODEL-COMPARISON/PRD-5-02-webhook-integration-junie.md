#### PRD-5-02: Webhook Integration - Control (Junie)

**Log Requirements**
- Junie: update task log under `knowledge_base/prds-junie-log/PRD-5-01-junie-control-log.md` (continue the implementation log).
- Capture:
    - Webhook controller implementation details.
    - Deduplication logic verification.
    - Integration test results.

---

### Overview
This PRD is the second part of Junie's "Control" implementation. Having established the outbound Write API, Junie must now implement the inbound Webhook Integration. The critical challenge is implementing the **Deduplication Logic** to prevent "Echo Loops" (where a Write API command triggers a Webhook which triggers another Write API command).

---

### Requirements

#### Functional
- **Webhook Controller:** Create `Api::V1::Webhooks::PrefabController`.
- **Inbound Processing:** Handle status updates for accessories and characteristics.
- **Deduplication (CRITICAL):** 
    - Before saving or processing an inbound event, query `ControlEvents` for a matching `accessory_id` and `characteristic` within the last 5 seconds.
    - If a match exists → SKIP processing (mark as 'echo' in logs).
- **Audit Logging:** Every inbound event must be logged to `AuditLog` with `source: 'webhook'`.

#### Non-Functional
- **Strict Compliance:** ZERO deviation from the `epic-5-strict-directive.md`.
- **Performance:** Ensure the deduplication query is indexed and performant.

#### Rails / Implementation Notes
- **Routes:** Add a POST endpoint for Prefab webhooks.
- **Controller:** Standard Rails API controller logic.

---

### Acceptance Criteria
- [ ] Webhook controller successfully receives and parses Prefab payloads.
- [ ] Deduplication logic correctly identifies and skips "Echo" events.
- [ ] Inbound events are persisted to `AuditLog`.
- [ ] All tests pass on the `epic-5/junie` branch.

---

### Test Cases

#### Integration (Minitest/RSpec)
- `test/integration/webhooks/prefab_controller_test.rb`: 
    - Covers successful inbound processing.
    - Covers deduplication hit (echo skipped).
    - Covers deduplication miss (new event processed).

---

### Manual Verification
1. Manually trigger a `Prefab::WriteApiService` call (Outbound).
2. Immediately (within 2 seconds) POST a matching status update to the Webhook endpoint.
3. Verify that the second event is skipped by checking the `AuditLog` or server logs.

---

### Rollout / Deployment Notes
- Implementation must be committed to the `epic-5/junie` branch.
