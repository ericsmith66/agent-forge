### Spike Findings: Tool Improvements and Unattended Execution

#### 1. Ollama Tool Enhancements (`ollama_prompt.py` & `.rb`)
During the spike, the core integration tools for Ollama were significantly upgraded and ported to Ruby to ensure parity and reliability.

*   **Reliability & Health Checks:**
    *   Implemented **Ollama Health Checks and Model Warm-up**: This eliminates "cold-start zombies" where the model fails to respond because it is still loading into VRAM.
    *   **Structured Failure Classification**: Replaced generic error messages with specific diagnostic codes (`cold_start`, `partial`, `question_unanswered`, `connection_error`, `ollama_error`).
*   **Performance Monitoring:**
    *   **Stale-chunk detection**: Identifies when a model hangs mid-generation.
    *   **Per-phase timing metrics**: Captures logs for each step of the prompt lifecycle to identify bottlenecks.
*   **Transport Flexibility:**
    *   The Ruby version (`ollama_prompt.rb`) implements two transport modes: **SocketIO** (Engine.IO long-polling) for real-time parity and **REST** fallback for environments with strict networking.
*   **AiderDesk Integration:**
    *   Added **Log Tailing** with error pattern detection specifically for Ollama-specific failures (CUDA errors, context length exceeded, etc.).

#### 2. Unattended Execution & Epic Implementation (Unknowns)
While the spike proved that AiderDesk + Claude/Qwen can write production code, scaling this to unattended "Epic-level" execution remains a challenge.

*   **Artifact Traceability:**
    *   *Question:* What do we do with log artifacts generated during sub-project execution?
    *   *Proposed Solution:* Link log artifacts back to the `agent-forge` root. By centralizing logs/memories, the orchestration agent maintains "Global Context" while the project-level agent handles "Local Implementation."
*   **State Management:**
    *   Unattended runs need better recovery logic for when an agent gets stuck in a "Fix loop" (as seen with Qwen). We need a mechanism to signal the `Orchestrator` to intervene or switch models.
*   **Autonomous Handoffs:**
    *   How to transition from one PRD to the next within an Epic without human intervention is still an "Unknown." We need to refine the "Task Monitoring" pattern to trigger the next task automatically upon successful verification.

#### 3. Summary of Implementation Status
*   **Capability Verified:** Production code generation via Claude and Qwen is stable.
*   **Constraints Validated:** Strict directives are required for model compliance.
*   **Infrastructure Ready:** Centralized task monitoring and improved Ollama tools provide the foundation for larger-scale automation.

#### 4. Epic-5 Testing Strategy (Multi-Model Comparison)
To refine our understanding of model capabilities during the Eureka rebuild, we will adopt a "Competitive Implementation" strategy for Epic-5:
1.  **Isolation:** Each PRD within Epic-5 will be implemented on its own Git branch.
2.  **Comparison:** Three agents will attempt the same PRD:
    *   **Junie** (Agent-Forge Native)
    *   **Claude (Sonnet)** (via AiderDesk)
    *   **Qwen3-Coder** (via AiderDesk + Ollama)
3.  **Metrics:** Compare code quality, security compliance (Open3 usage), test coverage, and execution time.
4.  **Prerequisite:** The **Symlink Plan** and **Agent/Skill hierarchy** must be fully implemented before this testing begins to ensure all models have access to the same "Strict Execution Directives."
