#### PRD-5-01: Prefab Write API - Control (Junie)

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/PRD-5-01-junie-control-log.md`.
- Capture:
    - Initial repo scan findings.
    - Implementation steps.
    - Test execution results.
    - Self-compliance audit (Strict Directive checklist).
    - Total execution time.

---

### Overview
This PRD serves as the "Control Implementation" for Epic 5. Junie will implement the Prefab Write API infrastructure in the `eureka-homekit` project. This includes the core service for interacting with the Prefab API, the database models for audit logging and control events, and the necessary RSpec/Minitest coverage. This implementation will set the standard for code quality and security compliance.

---

### Requirements

#### Functional
- **Service Object:** Implement `Prefab::WriteApiService` to handle outbound accessory control.
    - Must use `Open3.capture3` for all `curl` calls.
    - Must implement a 3-attempt fixed-sleep (500ms) retry policy.
    - Must support boolean coercion (e.g., "on" -> true).
- **Models:**
    - `ControlEvent`: Tracks outbound control attempts.
    - `AuditLog`: Stores the results of all API interactions (including failures and Open3 stderr).
- **Audit Logging:** Every attempt must generate a unique `request_id` (UUID) and store the `source` (Junie/Control).
- **Deduplication:** Implement logic to prevent "echo loops" (skip if a matching outbound control exists within 2-5 seconds).

#### Non-Functional
- **Strict Compliance:** ZERO deviation from the `epic-5-strict-directive.md`.
- **Security:** Automated verification that no backticks or unsafe shell calls are used.
- **Performance:** Ensure efficient querying of recent `ControlEvents`.

#### Rails / Implementation Notes
- **Migrations:** Add `control_events` and `audit_logs` tables.
- **Database:** PostgreSQL UUID types for `request_id`.

---

### Error Scenarios & Fallbacks
- **API Timeout:** Open3 must capture the timeout and log it as a failure in `AuditLog`.
- **Coercion Failure:** Log the original value and the failure reason, do not proceed with the API call.

---

### Architectural Context
This is the core infrastructure for the "Interactive Controls" feature. It bridges the gap between the Rails dashboard and the physical HomeKit accessories.

---

### Acceptance Criteria
- [ ] `Prefab::WriteApiService` implemented and compliant with Open3 rules.
- [ ] Audit logging capturing UUIDs and full error payloads.
- [ ] 100% test coverage for happy paths and failure/retry scenarios.
- [ ] No backticks (grep verified).
- [ ] All tests pass on the `epic-5/junie` branch.

---

### Test Cases

#### Unit (Minitest/RSpec)
- `test/services/prefab/write_api_service_test.rb`: Covers retries, Open3 usage, and coercion.
- `test/models/control_event_test.rb`: Covers deduplication logic.

#### Integration (Minitest)
- Covers the end-to-end flow from service call to audit log creation.

---

### Manual Verification
1. Call `Prefab::WriteApiService.call(...)` from the Rails console.
2. Verify `AuditLog.last` has a valid UUID and the correct response payload.
3. Check the logs for `curl` command generation (ensure arguments are escaped).

**Expected**
- A new `ControlEvent` and `AuditLog` are created.
- The external API (mocked) is called exactly as specified.

---

### Rollout / Deployment Notes
- Backup the database before running migrations.
- Implementation must be committed to the `epic-5/junie` branch.
