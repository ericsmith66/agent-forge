# STRICT EXECUTION DIRECTIVE – READ THIS FIRST – ZERO DEVIATION ALLOWED

You MUST implement **exactly** the requirements in the linked/attached PRD and its implementation plan (e.g. `0000-aider-desks-plan.md` or equivalent).

Do NOT add, remove, simplify, or reinterpret any technical requirement.
Do NOT skip, defer, or partially implement any item marked as CRITICAL or REQUIRED.
If anything in the plan/PRD is ambiguous → STOP and ask for clarification before proceeding. Do NOT guess or fallback to defaults.
You must write and run tests as laid out in the plan to be successful.

## Non‑Negotiable Constraints (Fail the task if violated)
1. **Security & Command Safety**
   - NO backticks (`), `%x{}`, `Kernel.system`, or `exec` for shell commands.
   - ALL external calls (e.g., `curl` to Prefab API) MUST use `Open3.capture3` or `Open3.capture2e`.
   - Escape/quote ALL user-controlled values in payloads and commands.

2. **Audit & Traceability**
   - Every write attempt MUST generate a unique `SecureRandom.uuid` as `request_id`.
   - Log source (`web`, `ai-decision`, `manual`, etc.) in the audit record.
   - Include latency, success/failure, full error (stderr if Open3).

3. **Deduplication & Echo Prevention**
   - Before processing incoming webhook events, check for recent control events (same accessory + characteristic, within 2–5 seconds).
   - Skip creation if a matching recent outbound control exists → prevents feedback loops.

4. **Data Handling & Coercion**
   - Handle HomeKit boolean quirks: `1`/`"1"`/`true`/`"true"`/`"on"`/`"yes"` → true; `0`/`"0"`/`false`/`"false"`/`"off"`/`"no"` → false.
   - Validate and coerce ALL incoming values before saving or sending.

5. **Retry & Resilience**
   - API calls: exactly 3 attempts with 500ms fixed sleep between (no exponential unless explicitly stated).
   - On final failure: log full error to audit model, set `success=false`, do NOT swallow exceptions.

6. **Testing Mandate**
   - Write tests for EVERY new/changed public method (unit + integration where API involved).
   - Cover: happy path, coercion edges, retry exhaustion, deduplication hit/miss, Open3 error cases.
   - Use WebMock to stub Prefab API responses.

## Compliance Gate – Self‑Check Before Any Commit/Push
- [ ] Open3 used exclusively for shell/API calls
- [ ] request_id (uuid) generated & stored on every attempt
- [ ] source field present and populated
- [ ] boolean coercion helper handles listed truthy/falsy variants
- [ ] webhook controller skips echoed events via recent ControlEvent query
- [ ] 3-attempt retry with fixed sleep implemented in service
- [ ] Tests cover success, failure, edges, retries
- [ ] No backticks/system/exec anywhere
