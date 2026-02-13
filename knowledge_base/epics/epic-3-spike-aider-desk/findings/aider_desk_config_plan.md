### AiderDesk Configuration Recommendation Plan (for `agent-forge` + `eureka-homekit`)

#### 1. Establish a clean, non-nested `.aider-desk` layout (no broad symlinks)
1. Create **physical** `.aider-desk/` folders in both repos:
   - `agent-forge/.aider-desk/`
   - `agent-forge/projects/eureka-homekit/.aider-desk/`
2. **Do not symlink the whole `.aider-desk/` directory.** Only symlink subfolders listed below to avoid the nesting bug and task-history bleed documented in Epic 3.
3. Ensure no `.aider-desk` folder is nested inside another `.aider-desk` path (avoids config invisibility and recursive symlink failures).
   - `ruby_junie:` This is critical. The "nested symlink" bug was a major blocker during the spike. Physical folders for the root `.aider-desk` are the safest path.

#### 2. Implement the **Shared Library** strategy for agents/skills/hooks/commands
1. Centralize shared configuration in:
   - `agent-forge/knowledge_base/aider-desk/configs/ror-agent-forge-config/`
2. Symlink the following **per project** (not the parent folder):
   - `.aider-desk/agents` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/agents`
   - `.aider-desk/skills` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/skills`
   - `.aider-desk/hooks` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/hooks`
   - `.aider-desk/commands` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/commands`
3. Keep `.aider-desk/tasks` **project-specific** and symlink to a centralized root monitoring folder:
   - Root: `agent-forge/tasks/projects/`
   - Example: `projects/eureka-homekit/.aider-desk/tasks` → `../../tasks/projects/eureka-homekit`
   - `ruby_junie:` This enables the Agent-Forge dashboard to monitor sub-project progress without polluting the root task history.

#### 3. Convert agents to **hierarchical Agent → Sub-Agent** structure
1. Refactor the `agents/` directory to include a **parent agent** with **sub-agents** (as per Epic 3 findings):
   - Example structure:
     - `agents/rails/agent.md`
     - `agents/rails/subagents/debug.md`
     - `agents/rails/subagents/refactor.md`
     - `agents/rails/subagents/ui.md`
2. Keep namesconsistent with the epic execution workflow in `0000-aider-desks-plan.md` (so agent routing is predictable).
   - `ruby_junie:` The hierarchical model allows us to share common Rails context at the parent level while specializing tools and rules at the sub-agent level.

#### 4. Make the **STRICT EXECUTION DIRECTIVE** a default rule
1. Create a **global rule** (in the shared config) that injects the full strict block from `Epic-5`:
   - Include all “Non-Negotiable Constraints” and “Compliance Gate” items.
2. Ensure the rule is auto-included for any PRD task run, especially `PRD-5-01` (Open3-only, audit logging, retries, boolean coercion, dedupe).
3. If you have project-specific rules, **prepend** the strict directive to avoid it being buried.
   - `ruby_junie:` Qwen's 95% compliance score was directly tied to this directive. It should be the "First Rule of Rails Agent Club."

#### 5. Align command templates with Epic 5 execution flow
1. Add **command templates** for each Epic 5 PRD to enforce uniform execution:
   - `commands/epic5/prd-5-01.md`, `commands/epic5/prd-5-02.md`, …
2. Each command should:
   - Load the relevant PRD file
   - Load `0000-aider-desks-plan.md`
   - Inject the strict directive rule
   - Require test execution as listed in the PRD
3. Provide commands for “Review”, “Implement”, and “Verify” per PRD.
   - `ruby_junie:` Standardized commands reduce human error during the handoff between PRDs.

#### 6. Configure model selection and fallback behavior
1. Use `qwen3-coder-next:latest` (Ollama) as **default for strict compliance**.
2. Use Claude for **short exploratory tasks** only when the strict directive is less critical.
3. Add explicit agent rules to **block backticks and system calls**, matching PRD-5-01 constraints.
   - `ruby_junie:` Qwen is our "Compliance Officer" for Epic-5. Claude remains the "Architect."

#### 7. Enforce task isolation + artifact traceability
1. Keep task state per project in `tasks/projects/<project-name>` as described in the symlink plan.
2. Ensure AiderDesk logs (for PRD execution) are referenced in the same project scope:
   - `knowledge_base/prds-junie-log/PRD-5-XX-*-log.md`
3. If using the orchestration dashboard, link log artifacts back to `agent-forge` root for monitoring, without sharing task history.
   - `ruby_junie:` Maintaining clear logs per PRD is essential for the "Competitive Implementation" comparison.

#### 8. Add guardrails for Epic 5’s testing and safety requirements
1. Add a global checklist rule that mirrors `0000-aider-desks-plan.md` compliance gate:
   - Open3-only, UUID request_id, retry policy, coercion helper, dedupe logic, WebMock usage, RSpec coverage.
2. Include a **verification command** that ensures:
   - All required tests are run
   - Logs are updated
   - No prohibited shell invocation is used
   - `ruby_junie:` This acts as an automated "Exit Interview" for each task.

#### 9. Validation steps (before Epic 5 execution begins)
1. Open AiderDesk in `agent-forge` and `projects/eureka-homekit` and confirm:
   - Agents/skills are visible (no missing configs)
   - Sub-agents are selectable
   - Rules injected include strict directive
2. Run a dry-run PRD command (without file edits) to confirm:
   - Correct PRD + plan files are loaded
   - Strict directive appears in system prompt
   - Logging path is correct
   - `ruby_junie:` dry-runs will prevent "Model Drift" before we commit to the actual code changes.
