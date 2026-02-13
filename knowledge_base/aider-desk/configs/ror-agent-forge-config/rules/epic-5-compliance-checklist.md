# Epic 5 Compliance Checklist

Use this checklist before finishing any Epic 5 PRD task.

- [ ] Strict directive loaded before PRD-specific instructions
- [ ] `Open3.capture3`/`capture2e` used for all external calls
- [ ] `SecureRandom.uuid` generated per write attempt
- [ ] Audit record includes `source`, latency, success, and error details
- [ ] Boolean coercion helper handles HomeKit truthy/falsy values
- [ ] Webhook dedupe prevents echo loops (2–5 second window)
- [ ] 3-attempt retry with 500ms fixed sleep implemented
- [ ] Tests cover happy path, edge cases, and failures
- [ ] WebMock used for Prefab API stubs
