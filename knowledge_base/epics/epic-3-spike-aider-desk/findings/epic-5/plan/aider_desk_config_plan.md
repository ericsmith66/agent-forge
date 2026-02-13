# AiderDesk Configuration Plan for Epic 5 (Eureka HomeKit)

This document is the consolidated workproduct for configuring AiderDesk to execute Epic 5 safely and consistently across `agent-forge` and `projects/eureka-homekit`. It incorporates the Epic 3 spike findings (symlink pitfalls, agent hierarchy) and the Epic 5 execution constraints (strict directive, Open3-only calls, testing mandates).

## 1) Goals
- Ensure AiderDesk reliably observes shared `agents`, `skills`, `hooks`, and `commands` without config invisibility or recursive symlink failures.
- Enforce the **STRICT EXECUTION DIRECTIVE** and **Non‑Negotiable Constraints** for Epic 5.
- Keep task history isolated per project while allowing centralized monitoring from `agent-forge`.
- Provide predictable, repeatable PRD execution commands aligned to `0000-aider-desks-plan.md`.

## 2) Required Constraints (Epic 5 Compliance)
The following must be injected as global rules for any Epic 5 run:
- Open3-only external calls (no backticks, `system`, `exec`).
- `SecureRandom.uuid` per write attempt (`request_id`).
- Source field in control audit records.
- Fixed 3-attempt retry with 500ms sleep.
- Boolean coercion helper for HomeKit quirks.
- Webhook deduplication to avoid echo loops.
- RSpec coverage for all public methods and edge cases.

`ruby_junie: This is mandatory for PRD-5-01 and must be injected before any per-PRD rule so it is never buried.`

## 3) Anti‑Nesting Strategy for `.aider-desk/`
**Do not symlink the entire `.aider-desk/` folder.** Create a physical directory and only link subfolders:

- `agent-forge/.aider-desk/`
- `agent-forge/projects/eureka-homekit/.aider-desk/`

This avoids the “nested `.aider-desk`” bug that causes AiderDesk to miss agents or skills.

`ruby_junie: The spike showed config invisibility when `.aider-desk` itself was a symlink or nested.`

## 4) Shared Library Layout
Centralize shared configuration in:

```
agent-forge/knowledge_base/aider-desk/configs/ror-agent-forge-config/
```

Per project, symlink only these subfolders:

- `.aider-desk/agents` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/agents`
- `.aider-desk/skills` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/skills`
- `.aider-desk/hooks` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/hooks`
- `.aider-desk/commands` → `knowledge_base/aider-desk/configs/ror-agent-forge-config/commands`

## 5) Hierarchical Agent Model
Transition from a flat agent list to a **parent → sub‑agent** structure:

```
agents/
  rails/
    agent.md
    subagents/
      debug.md
      refactor.md
      ui.md
```

`ruby_junie: This mirrors how we actually work (family + specialization) and avoids duplicate rule drift.`

## 6) Centralized Task Monitoring (No History Bleed)
Keep task history per project while enabling root-level monitoring:

- Root directory: `agent-forge/tasks/projects/`
- Project link: `projects/eureka-homekit/.aider-desk/tasks` → `../../tasks/projects/eureka-homekit`

`ruby_junie: This preserves isolation but still lets the orchestration dashboard watch progress.`

## 7) Command Templates for Epic 5 PRDs
Create standardized commands for each PRD to load:

- The PRD file (e.g., `PRD-5-01-prefab-write-api.md`)
- The execution plan (`0000-aider-desks-plan.md`)
- The strict directive rule

Suggested command groups:
- `epic5:prd-5-01:review`
- `epic5:prd-5-01:implement`
- `epic5:prd-5-01:verify`

`ruby_junie: Commands must enforce tests, not just encourage them.`

## 8) Model Selection & Safety Defaults
- Default to `qwen3-coder-next:latest` for strict compliance tasks.
- Use Claude only for exploratory or low‑risk tasks.
- Add a rule that explicitly blocks backticks and shell execution shortcuts.

## 9) Testing & Verification Guardrails
Add a shared rule/checklist that mirrors the Compliance Gate from `0000-aider-desks-plan.md`:

- Open3-only calls
- request_id and source logging
- boolean coercion helper
- deduplication check
- retry policy
- WebMock usage
- RSpec coverage and reruns

## 10) Validation Steps (Pre‑Epic 5)
Before any PRD execution:
1. Confirm AiderDesk loads agents/skills/hooks/commands in both repos.
2. Confirm strict directive appears in the system prompt.
3. Run a dry‑run PRD command to validate file loading and log paths.

---

If approved, this plan is the source of truth for the `bin/setup-aider-desk` automation and the restructuring of `ror-agent-forge-config`.
