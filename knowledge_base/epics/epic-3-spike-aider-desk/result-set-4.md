# Infrastructure Fixes & Improved Interaction (Result Set 4)

Date: 2026-02-10
Reviewer: Junie
Version: V1

## 1. Objective
Document the technical fixes applied to `AiderDesk::Client` to resolve infrastructure-level issues (504 timeouts) and improve the visibility of agent-mode interactions (tool calls, idle detection).

## 2. Technical Fixes Applied

### A. 504 Gateway Timeout Mitigation (Automatic Retries)
- **Problem:** When AiderDesk or its Python connector is initializing (especially with local Ollama models), the API frequently returns 504 Gateway Timeouts. This previously broke the evaluation scripts immediately.
- **Fix:** Modified `AiderDesk::Client#execute` to implement an **Exponential Backoff Retry Strategy** specifically for 504 errors.
  - **Max Retries:** 3
  - **Wait Time:** 2s, 4s, 8s
- **Outcome:** The client will now gracefully wait for the infrastructure to stabilize instead of failing the task.

### B. Tool Call Visibility (Interception)
- **Problem:** Agent Mode uses internal tools (e.g., `todo---set_items`, `memory---retrieve`) which were "invisible" to the orchestrator, leading to a "black box" experience during planning phases.
- **Fix:** Updated `run_prompt_and_wait` to parse the `messages` history for assistant role messages containing tool signatures (`{"name": ...}`).
- **Outcome:** Tool calls are now logged at the `INFO` level, providing real-time visibility into the agent's "thinking" steps.

### C. Idle State Detection (Stall Prevention)
- **Problem:** Tasks often paused silently because AiderDesk was waiting for human approval in the UI (e.g., "Add file to context").
- **Fix:** Enhanced polling to monitor the task `state`. If a task enters the `idle` state but is not marked as `completed`, the client now logs a high-signal warning.
- **Outcome:** The orchestrator can now detect and report when it's waiting for human intervention, preventing long periods of "blind" waiting.

## 3. Options for Better Interaction (Strategic)

To further improve Agent Mode support in Epic 4, we should consider:

1. **Auto-Approval of Safe Tools:** Configure AiderDesk to auto-approve non-destructive tools like `memory---retrieve` or `todo---set_items` to reduce human-in-the-loop friction.
2. **Pre-flight Context Injection (PFCI):** Instead of waiting for the agent to ask for files, the orchestrator should use the `/api/add-context-file` endpoint to proactively inject relevant PRDs and style guides before the prompt starts.
3. **Task Restart capability:** Implement a "Soft Reset" in the orchestrator that can clear context and restart a prompt if a 504 or a stall is detected that retries cannot fix.

## 4. Conclusion
These client-level improvements resolve the primary blockers encountered during the Epic 3 Spike and provide a robust foundation for the multi-agent orchestrator in Epic 4.
