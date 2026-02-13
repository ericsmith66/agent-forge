### Proposed Plan for Refined Symlink Strategy

Based on the review of `knowledge_base/aider-desk/configs/aider-desk-dot-dir.md` and the current state of the repository, the existing symlink strategy needs "tweaking" to prevent state bleed (like `tasks/` history) while allowing for a shared, maintainable set of `agents` and `skills`.

#### 1. Analysis of Current Issues
*   **Broad Symlinking:** Some projects may be symlinking the entire `.aider-desk/` directory, which causes `tasks/` (chat history and task state) to be shared across unrelated projects.
*   **Redundant Configs:** `agents` and `skills` are currently duplicated across the root `.aider-desk/`, `~/.aider-desk/`, and various config directories in `knowledge_base/`.
*   **Recursive Symlinks:** Evidence was found of `.aider-desk` being symlinked inside another `.aider-desk` directory (e.g., in `projects/eureka-homekit`), which can cause loading errors.

#### 2. Proposed "Shared Library" Strategy
Instead of symlinking the whole `.aider-desk/` folder, we will adopt a **selective symlinking** approach:

*   **Central Library:** All shared Rails agents, skills, hooks, and commands will live in `knowledge_base/aider-desk/configs/ror-agent-forge-config/`.
*   **Shared Assets:** Each project will symlink `agents/`, `skills/`, `hooks/`, and `commands/` to the Central Library.
*   **Task Monitoring (Centralized):** To allow `agent-forge` to monitor progress across all sub-projects, we will implement a **Centralized Task Storage** pattern:
    *   The root `agent-forge` repo will have a `tasks/projects/` directory.
    *   Each sub-project's `.aider-desk/tasks` directory will be a **symlink** pointing to `agent-forge/tasks/projects/<project-name>`.
    *   This keeps task data accessible to the orchestration dashboard while preventing history bleed between different projects.

#### 3. Implementation Plan

**Phase 1: Consolidation (Preparation)**
1.  Verify/Consolidate shared assets (agents, skills, hooks, commands) in `knowledge_base/aider-desk/configs/ror-agent-forge-config/`.
2.  Create the monitoring directory in the root: `tasks/projects/`.
3.  Add `tasks/projects/*` to the root `.gitignore`.

**Phase 2: Project Cleanup & Linking**
1.  **Root Project (`agent-forge/`):**
    *   Link `.aider-desk/agents`, `.aider-desk/skills`, `.aider-desk/hooks`, and `.aider-desk/commands` to `knowledge_base/aider-desk/configs/ror-agent-forge-config/`.
    *   Link `.aider-desk/tasks` to the root's local `tasks/agent-forge` (for its own internal tasks).
2.  **Sub-Projects (e.g., `projects/eureka-homekit`):**
    *   Remove existing broad symlinks.
    *   Create physical `.aider-desk/` folder.
    *   Symlink `agents/`, `skills/`, `hooks/`, and `commands/` to the Central Library.
    *   Symlink `.aider-desk/tasks` -> `../../tasks/projects/eureka-homekit`.

**Phase 3: Automation & Documentation**
1.  Create a lightweight script `bin/setup-aider-desk` that:
    *   Initializes the project-local `.aider-desk/` structure.
    *   Creates the necessary symlinks to the Shared Library.
    *   Ensures `tasks/` is ignored by Git.
2.  Update the `projects/README.md` and `aider-desk-dot-dir.md` with these instructions.

#### 4. Verification
1.  Verify that AiderDesk in the root project correctly loads the shared agents.
2.  Verify that `projects/eureka-homekit` loads the same agents but maintains its own separate `tasks/` history.

**Please review this plan. I am ready to implement these changes once you approve.**