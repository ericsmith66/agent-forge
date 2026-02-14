### Finding: Token Exhaustion During Claude-4.5-Sonnet Run & AiderDesk Task Forking API

**Date:** 2026-02-13
**Context:** Epic 5 Multi-Model Comparison — Claude-4.5-Sonnet Challenger Run

---

#### 1. Incident: Token Exhaustion

During the Claude-4.5-Sonnet challenger run on the `epic-5/claude` branch, the model ran out of tokens mid-session at approximately **85% completion** (52 of 61 tasks). The session ended abruptly, requiring manual recovery assistance from **Forge-Analyst** (PyCharm twin).

**Impact:**
- Claude had completed 5 full PRDs (5-01, 5-04, 5-02, 5-03, 5-06) plus partial PRD-5-07 (Fan Controls).
- No code was lost — AiderDesk persists file edits to disk immediately — but the task context and conversation history were truncated.
- Recovery required Forge-Analyst to walk the user through resuming from the last known good state.

**Root Cause:**
- Claude-4.5-Sonnet's context window was consumed by the cumulative weight of:
  - Multiple PRD files loaded into context.
  - The growing codebase (25+ new files, ~2,800 lines).
  - Claude's own "Self-Documentation" artifacts (`IMPLEMENTATION-SUMMARY.md`, `REMAINING-PRDS-GUIDE.md`, `FINAL-STATUS.md`).
  - Repeated "Progress Report" summaries after each context reset.
- AiderDesk's "Review & Verify" lifecycle added additional token overhead per cycle.

**Lesson:** High-tier models that produce verbose self-documentation (a strength for maintainability) accelerate token exhaustion. The "Memory Hardening" strategy (writing guides for future self) is effective for architectural continuity but expensive in tokens.

---

#### 2. Discovery: AiderDesk REST API for Task Forking

During recovery, Forge-Analyst identified that AiderDesk exposes a **REST API** that can be used to programmatically fork a task before the token limit is reached. This is a critical capability for unattended or semi-unattended epic execution.

**API Endpoints:**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/project/tasks` | GET | List all tasks for a project (`?projectDir=...`) |
| `/project/tasks/load` | POST | Load task messages (`{ projectDir, id }`) |
| `/project/tasks/fork` | POST | Fork a task from a specific message (`{ projectDir, taskId, messageId }`) |

**Prerequisites:**
- The **API server** must be enabled in AiderDesk settings (Server/Remote API).
- If authentication is configured, add basic auth to all requests (`-u user:pass`).

**Example `curl` Sequence:**
```bash
# 1) List tasks for the project
curl "http://<HOST>:<PORT>/project/tasks?projectDir=/Users/ericsmith66/development/agent-forge/projects/eureka-homekit"

# 2) Load task messages to find the latest messageId
curl -X POST "http://<HOST>:<PORT>/project/tasks/load" \
  -H "Content-Type: application/json" \
  -d '{"projectDir":"/Users/ericsmith66/development/agent-forge/projects/eureka-homekit","id":"<TASK_ID>"}'

# 3) Fork from a specific message (before token exhaustion)
curl -X POST "http://<HOST>:<PORT>/project/tasks/fork" \
  -H "Content-Type: application/json" \
  -d '{"projectDir":"/Users/ericsmith66/development/agent-forge/projects/eureka-homekit","taskId":"<TASK_ID>","messageId":"<MESSAGE_ID>"}'
```

---

#### 3. Critical Limitation: No Per-Task Token Meter in REST API

There is **no REST endpoint that directly reports "this task is near the token limit."** The UI's token progress bar is computed from `tokensInfo` + `maxInputTokens` (model context size), but **`tokensInfo` is not returned by `/project/tasks/load`** in the REST API.

**What IS available:**
- `/usage` endpoint — returns **aggregate** token usage over a time window (not per-task).
- Fields include: `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`.

**What is NOT available via REST:**
- Per-task `tokensInfo` (the data that drives the UI's token bar).
- `maxInputTokens` for the active model.

**Implication:** Any API-based automation must **approximate** token usage using the `/usage` endpoint with a time-window heuristic, then call the fork endpoint when the threshold is reached. This is a practical trigger, not a precise one.

**Combined API Example (Detect + Fork):**
```bash
# ---- config ----
SERVER="http://<HOST>:<PORT>"
PROJECT_DIR="/Users/ericsmith66/development/agent-forge/projects/eureka-homekit"
MODEL_MAX_INPUT_TOKENS=128000   # set your model's context window
THRESHOLD_PCT=85

# ---- 1) list tasks to get the taskId ----
TASK_ID=$(curl -s "$SERVER/project/tasks?projectDir=$PROJECT_DIR" | jq -r '.[0].id')

# ---- 2) load task to get latest messageId ----
MESSAGE_ID=$(curl -s -X POST "$SERVER/project/tasks/load" \
  -H "Content-Type: application/json" \
  -d "{\"projectDir\":\"$PROJECT_DIR\",\"id\":\"$TASK_ID\"}" \
  | jq -r '.messages[-1].id')

# ---- 3) get usage for recent window (last 2 hours) ----
FROM=$(date -u -v-2H +"%Y-%m-%dT%H:%M:%SZ")
TO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

TOKENS_USED=$(curl -s "$SERVER/usage?from=$FROM&to=$TO" \
  | jq '[.[] | .input_tokens + .output_tokens + .cache_read_tokens + .cache_write_tokens] | add')

THRESHOLD_TOKENS=$(( MODEL_MAX_INPUT_TOKENS * THRESHOLD_PCT / 100 ))

if [ "$TOKENS_USED" -ge "$THRESHOLD_TOKENS" ]; then
  echo "Near limit ($TOKENS_USED >= $THRESHOLD_TOKENS). Forking..."
  curl -s -X POST "$SERVER/project/tasks/fork" \
    -H "Content-Type: application/json" \
    -d "{\"projectDir\":\"$PROJECT_DIR\",\"taskId\":\"$TASK_ID\",\"messageId\":\"$MESSAGE_ID\"}"
else
  echo "Not near limit yet ($TOKENS_USED < $THRESHOLD_TOKENS)."
fi
```

**Accuracy Warning:** `/usage` is aggregate usage across all tasks, not a true per-task context window size. For exact "near limit" detection, you would need `tokensInfo` + `maxInputTokens` — the same data used by the UI — which is currently only available inside the app (not via REST).

**Potential Enhancement:** Add a small REST endpoint that returns `tokensInfo` for a specific task, or use the desktop IPC layer if automating inside the app.

---

#### 4. Automation Opportunity: Pre-Emptive Forking

AiderDesk does **not** have a built-in "auto-fork at token limit" toggle. The automation logic must be external. A lightweight monitoring script could:

1. **Track token usage** — using the `/usage` endpoint with a time-window heuristic (see Section 3 above).
2. **Trigger a fork** at ~80–90% of the model's context window.
3. **Resume the new task** with a condensed "Handoff Prompt" that includes:
   - The current PRD and its completion status.
   - A pointer to the model's own `REMAINING-PRDS-GUIDE.md` (if it created one).
   - The Strict Execution Directive.

**Proposed Script:** `bin/aider-desk-auto-fork`
- **Inputs:** Server URL/port, auth credentials, project directory, model context size, token threshold (percentage or count).
- **Behavior:** Polls `/usage` on a timer, estimates token consumption against the threshold, and forks when the threshold is reached.
- **Output:** Logs the fork event and the new task ID for traceability.

**Open Questions (for future implementation):**
- The `/usage` heuristic is imprecise — can we contribute a PR to AiderDesk to expose `tokensInfo` via REST?
- Should the fork script also inject a "Continuation Prompt" into the new task, or should that be manual?
- Can we integrate this with the `hooks/` system (e.g., a post-prompt hook that checks token usage)?
- What `MODEL_MAX_INPUT_TOKENS` values should we use for each model (Gemini Flash, Claude 4.5 Sonnet, Qwen)?

---

#### 5. Implications for the Multi-Model Comparison

| Model | Token Management | Recovery Strategy |
|-------|-----------------|-------------------|
| **Gemini Flash (Junie)** | No exhaustion observed (per-PRD resets via orchestrator). | N/A — external orchestration prevented accumulation. |
| **Claude-4.5-Sonnet** | Exhausted at 85% due to verbose self-documentation + multi-PRD continuous run. | Manual recovery via Forge-Analyst; future: auto-fork. |
| **Qwen (Pending)** | Expected to be more vulnerable (smaller context window on Ollama). | Pre-emptive forking recommended from the start. |

**Key Takeaway:** For unattended epic execution, **pre-emptive task forking** is not optional — it is a required infrastructure component. The AiderDesk REST API makes this feasible without modifying the core application.

---

#### 7. AiderDesk Auto-Completion Behavior (READY_FOR_REVIEW Interrupts)

AiderDesk runs an **automatic task-state classifier** on the last assistant message. If the response sounds like the work is finished (e.g., contains "complete," "done," "finished," "ready for review"), it transitions the task state to **`READY_FOR_REVIEW`** and the UI prompts the user to mark the task complete. This caused repeated interruptions during the Claude-4.5-Sonnet run, where progress reports triggered the classifier and broke the continuous execution flow.

**Impact on Epic 5:**
- After each "Progress Report" (which Claude generated autonomously), AiderDesk paused and asked to mark the task complete.
- The user had to manually tell Claude to continue, which added latency and consumed additional tokens on the "keep going" exchange.
- This behavior contributed to the context resets observed during the run — each pause created a natural break point where AiderDesk started a new task context.

**Mitigation — Standing Instruction:**
Add the following to the top of every task prompt (or bake it into the agent's `customInstructions`):

```
Do not mark the task complete or READY_FOR_REVIEW unless I explicitly say "mark complete". Always continue with the next step and keep the task In Progress.
```

When the classifier triggers anyway, reply with:
```
Continue. Keep the task In Progress and do not mark complete.
```

**Why this works:** The task-state classifier only inspects the latest response. If the model avoids "completion" language and the user reinforces "In Progress," the classifier will not transition the state.

**Recommendation:** Add this standing instruction to the shared `ror-agent-forge-config/rules/` as a default rule (e.g., `task-continuity.md`) so it is automatically injected into every AiderDesk session. This prevents the interruption pattern without requiring manual prompt engineering per task.

---

#### 8. Recommendations

1. **Immediate:** Document the AiderDesk API server URL and auth settings in the project's `.env` or `knowledge_base/aider-desk/` for easy reference.
2. **Short-term:** Build `bin/aider-desk-auto-fork` as a simple Ruby script (using `Net::HTTP` — consistent with `ollama_prompt.rb` patterns).
3. **Medium-term:** Integrate token monitoring into the AiderDesk `hooks/` system so forking is triggered automatically during any long-running task.
4. **Epic-level:** Add a "Token Budget" field to the PRD template so each task has an explicit ceiling, and the orchestrator can plan forks in advance.
