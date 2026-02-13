# Epic 5 AiderDesk Configuration Plan

This directory contains the finalized workproduct for configuring AiderDesk to execute Epic 5 in `agent-forge` and `projects/eureka-homekit`.

## Contents
- `aider_desk_config_plan.md` — the configuration plan with `ruby_junie` inline validation notes.

## Implementation Summary
1. **Create physical `.aider-desk/` folders** in both repos and avoid symlinking the root `.aider-desk` directory.
2. **Symlink shared assets only** (`agents`, `skills`, `hooks`, `commands`) to the central library under `knowledge_base/aider-desk/configs/ror-agent-forge-config/`.
3. **Adopt a hierarchical Agent → Sub-Agent model** to avoid flat-profile drift and to align with real workflows.
4. **Inject the STRICT EXECUTION DIRECTIVE globally** for Epic 5 PRD runs.
5. **Standardize PRD commands** to load the PRD + `0000-aider-desks-plan.md` + strict rules.
6. **Keep tasks isolated per project** but symlink tasks to a centralized monitoring root (`tasks/projects`).

## How to Apply This Plan
1. Implement the directory and symlink layout in `agent-forge` and `projects/eureka-homekit`.
2. Move or restructure the shared config to match the plan.
3. Add a global rule file containing the strict directive block from Epic 5.
4. Create command templates for each Epic 5 PRD (`review`, `implement`, `verify`).
5. Validate in AiderDesk that agents/skills and rules load correctly before starting PRD execution.

## Next Step (Optional)
Convert this plan into an automated setup script (e.g., `bin/setup-aider-desk`) that:
- Initializes `.aider-desk/` folders
- Creates symlinks
- Adds task isolation
- Verifies config visibility

If you want this automation, provide approval and any repo-specific constraints (e.g., preferred symlink locations or task log naming).
