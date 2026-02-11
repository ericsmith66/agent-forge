# Alternative Endpoint Analysis: Supporting Agent Mode (Result Set 3)

Date: 2026-02-10
Reviewer: Junie
Version: V1

## 1. Objective
Analyze AiderDesk's available API endpoints to improve the visibility of Agent Mode's internal processes (planning, tool execution) and reduce friction during implementation tasks. This constitutes **Result Set 3** of the Epic 3 Spike.

## 2. API Analysis Findings

### A. Lack of Streaming/Event Endpoints
Exhaustive search of `knowledge_base/aider-desk/docs/rest-endpoints.md` confirms there are no Server-Sent Events (SSE) or WebSocket streaming endpoints available in the current AiderDesk version.
- **Impact:** Polling is the only method for monitoring progress.
- **Recommendation:** Refine the polling logic to parse the full message history rather than just looking for `response-completed`.

### B. Internal Tool Call Visibility
During Config 2 (Agent Mode), AiderDesk triggered tool calls like `todo---set_items` and `memory---retrieve`.
- **Finding:** These tool calls appear in the `messages` array returned by `POST /api/project/tasks/load`.
- **Issue:** Our current client only reports `user` and `assistant` roles in a simplified way.
- **Solution:** Update `AiderDesk::Client` to detect and log messages where `role == 'assistant'` and `content` contains tool call signatures. This will allow the orchestrator to see "thinking" steps.

### C. The 504 Timeout Pattern
Config 3 (Ollama) frequently hit 504 Gateway Timeouts during project initialization.
- **Finding:** This occurs when the AiderDesk-to-Python connector is busy spawning the local model process or initializing a new project directory.
- **Solution:** Implement an exponential backoff retry strategy in the `AiderDesk::Client#post` method specifically for 504 status codes.

---

## 3. Support for Agent Mode: Strategic Recommendations

### A. Pre-flight Context Injection (PFCI)
One of the biggest friction points in Agent Mode is the "Add file to context" pause. 
- **Strategy:** Automate context building. Before the first prompt, the orchestrator should:
    1. Identify relevant files using a simple keyword match or tree traversal.
    2. Call `/api/add-context-file` for each identified file.
    3. This ensures the agent starts with all the "tools" it needs, bypassing the initial planning stalls.

### B. Tool Call Interception
The Ruby client should be enhanced to "intercept" known tool calls that require human approval.
- **Example:** If a message contains `todo---set_items`, the client could automatically log it as a "Plan Proposed" event.
- **Future:** Explore AiderDesk settings to auto-approve certain safe tools (like `memory---retrieve`).

### C. Improved Task State Monitoring
Task states like `busy`, `idle`, and `error` are returned by `/api/project/tasks/load`.
- **Improvement:** Instead of just checking for `completed`, the client should monitor for the `idle` state. If a task is `idle` but not `completed`, it usually means it's waiting for human intervention in the UI (like a plan approval).

---

## 4. Next Steps for Epic 3 & 4
1. **Implement PfCI Service:** Create `app/services/aider_desk/context_injector.rb`.
2. **Refactor Client Polling:** Update `run_prompt_and_wait` to handle 504s and log tool-related messages.
3. **Verify in Epic 4:** Use these enhancements as the foundation for the Agent Orchestrator.
