#### PRD-5-00: Environment Standardization & Config Refinement

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/PRD-5-00-env-setup-log.md`.
- Include verification of symlink paths and config visibility in the log.

---

### Overview
Before the multi-model comparison can begin, we must ensure a "Fair & Equal" environment for all participants. This PRD involves refining the general Rails configurations (copied from Epic-5 findings) into project-specific standards for `agent-forge` and creating the `bin/setup-aider-desk` automation script. This script will implement the selective symlink strategy and fix the "nested configuration" bug once and for all.

---

### Requirements

#### Functional
- **Config Refinement:** Update the `ror-agent-forge-config` library (in `knowledge_base/aider-desk/configs/`) to incorporate the specific recommendations from `config_refinement_feedback.md`:
    - Harden the `STRICT EXECUTION DIRECTIVE` with negative constraints (no backticks).
    - Update the `rails` parent agent with explicit delegation triggers for `debug` and `ui` subagents.
    - Add the "Retry & Sleep" pattern to the `rails-open3-safe-exec` skill.
- **Automation Script (`bin/setup-aider-desk`):** Create a Ruby script that:
    - Creates physical `.aider-desk/` directories in the root and specified project paths.
    - Selectively symlinks `agents`, `skills`, `hooks`, and `commands` to the shared library.
    - Implements centralized task monitoring by symlinking `.aider-desk/tasks` to `tasks/projects/<project_name>`.
    - Validates that no `.aider-desk` folder is nested inside another.
- **Backup Strategy:** Implement a lightweight backup check in the setup script to ensure existing task history is preserved before symlinking.

#### Non-Functional
- **Idempotency:** The setup script must be safe to run multiple times.
- **Portability:** Use relative symlinks to ensure the repository remains functional when moved between environments.

#### Rails / Implementation Notes
- **Script Language:** Ruby (to ensure compatibility with the project stack).
- **Paths:** Central library at `knowledge_base/aider-desk/configs/ror-agent-forge-config/`.

---

### Error Scenarios & Fallbacks
- **Existing Directory:** If `.aider-desk/agents` is a physical folder instead of a symlink → Rename to `.aider-desk/agents.bak` and create the symlink.
- **Missing Source:** If the shared library is missing → Exit with a descriptive error message.

---

### Architectural Context
This PRD establishes the "Rules of Engagement" for the competitive implementation. It ensures that regardless of which model is running (Junie, Claude, or Qwen), they all see the same constraints and have the same specialized skills available.

---

### Acceptance Criteria
- [ ] `ror-agent-forge-config` refined with project-specific directives.
- [ ] `bin/setup-aider-desk` created and functional.
- [ ] `agent-forge/.aider-desk` and `projects/eureka-homekit/.aider-desk` correctly symlinked.
- [ ] AiderDesk (local) confirms agents/skills are visible and subagents are selectable.
- [ ] No nested `.aider-desk` directories remain.

---

### Test Cases

#### Unit (Minitest)
- N/A (Manual script verification preferred for environment setup).

#### Integration (Minitest)
- N/A.

#### System / Smoke (Capybara)
- N/A.

---

### Manual Verification
1. Run `bin/setup-aider-desk`.
2. Run `ls -la .aider-desk` and `ls -la projects/eureka-homekit/.aider-desk`.
3. Open AiderDesk UI and select the `rails` profile.
4. Verify `debug` and `ui` subagents are available.

**Expected**
- All shared assets are symlinked to the central library.
- Task history is isolated per project but centrally accessible in `tasks/projects/`.

---

### Rollout / Deployment Notes
- This is a development-only configuration update.
- Ensure the root `.gitignore` is updated to handle the new `tasks/projects/` directory.
