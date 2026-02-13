# Custom Instructions (Rails)

Follow the Epic 5 strict directive and compliance checklist. When implementing controls or write APIs:

- Use `Open3.capture3` or `capture2e` for all external calls.
- Generate `request_id` with `SecureRandom.uuid` for each write attempt.
- Log `source`, latency, and errors for control actions.
- Apply 3-attempt fixed retry with 500ms sleep.
- Use robust boolean coercion for HomeKit values.
- Apply webhook deduplication to prevent echo loops.
