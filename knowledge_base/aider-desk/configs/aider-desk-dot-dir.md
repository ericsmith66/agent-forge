# `.aider-desk/` in AiderDesk: Hooks, Commands, Rules, Tasks

Audience: senior developers who want to understand how AiderDesk persists project‑local configuration and execution artifacts.

## Purpose and Scope

`.aider-desk/` is **project‑local configuration + state**. It is intentionally separate from global settings (e.g., `~/.aider-desk/`) so you can:

- override agents/commands/rules on a per‑project basis,
- keep task state (context, settings, chat history) scoped to a repo,
- isolate hooks so project automation doesn’t leak across repositories.

The directories below are the primary ones you asked about:

```
.aider-desk/
├── hooks/      # JS hook modules (project-level)
├── commands/   # Markdown command templates (project-level)
├── rules/      # Project rules (markdown) injected into context
└── tasks/      # Per-task state (settings + context + chat history)
```

## `hooks/` — Lifecycle Automation (JavaScript)

**What it is:**
Project‑level hook modules loaded by the `HookManager`. Each file is a `.js` module that exports one or more hook functions keyed by event name.

**How it loads:**
- Global hooks are loaded from `~/.aider-desk/hooks`.
- Project hooks are loaded from `<project>/.aider-desk/hooks`.
- Both directories are **watched with `chokidar`** and reloaded on change.
- Runtime execution order is: **global hooks first, then project hooks**.
- Files are loaded via `require()`; errors are logged but do not crash the app.

**Implications:**
- If you need deterministic execution order, prefix filenames (e.g., `01-`, `02-`).
- Hooks can **block** or **mutate** events depending on the hook contract.

## `commands/` — Reusable Prompt Templates

**What it is:**
Markdown files with YAML front matter that define custom command templates. These are surfaced as custom commands in the UI/agent.

**How it loads:**
- Global commands from `~/.aider-desk/commands`.
- Project commands from `<project>/.aider-desk/commands`.
- Directory recursion is supported; subfolders create **namespaced commands** using `:`.
    - Example: `commands/review/security.md` → command name `review:security`.

**Override behavior:**
- Global commands are loaded first, project commands **override** by name.

**Template behavior:**
- `arguments` are defined in front matter.
- Template supports placeholders like `{{ARGUMENTS}}`, `{{1}}`, `{{2}}`, etc.
- Commands may execute shell substitutions if configured (see `executeShellCommands`).

## `rules/` — Context Rules and Guardrails (Markdown)

**What it is:**
Project rules in Markdown, injected as **read‑only context files** when rule inclusion is enabled.

**Sources of rules (in order):**
1. **Global rules**: `~/.aider-desk/rules/*.md`
2. **Project root `AGENTS.md`** (if present)
3. **Project rules**: `<project>/.aider-desk/rules/*.md`
4. **Agent profile rule files** (from agent `rules/` directories)

**Where it is used:**
- The task context includes these rule files as read‑only context.
- Aider is also started with `--read .aider-desk/rules` when the setting `addRuleFiles` is enabled and that directory exists.

**Practical guidance:**
- Use project rules for policy and invariants (coding standards, architectural constraints).
- Keep rules small and explicit; they are injected into prompt context.

## `tasks/` — Per‑Task State and Traceability

**What it is:**
Execution state for each task ID, stored under `.aider-desk/tasks/<taskId>/`.

**Observed files:**
- `settings.json` — task metadata (`TaskData`) such as model, profile, and state.
- `context.json` — persisted conversation context (messages + files).
- `.aider.chat.history.md` — Aider chat history file for that task.

**Important behavior:**
- Task storage is **always under the project base directory**, even when using a worktree. File operations use the worktree path, but task metadata stays with the base project.
- Empty or internal tasks may be cleaned up on close.

**Practical guidance:**
- Keep `.aider-desk/tasks` out of Git.
- It’s safe to delete a specific task folder if you want to discard history for that task.

## Symlinking `.aider-desk/` Across Projects: Side Effects

**Short version:** symlinking the **entire** `.aider-desk/` across multiple projects creates **shared state** and can cause cross‑project bleed, unexpected overrides, and concurrency issues.

### Side effects to be aware of

1. **Task collision and cross‑project history**
    - All projects would write to the same `.aider-desk/tasks` path.
    - Task IDs are UUIDs, so collisions are unlikely, but **task history from different repos will co‑exist** and may be confusing or leak context.

2. **Hooks and commands become global without explicit intent**
    - A project‑specific hook or command becomes active in all projects that share the symlink.
    - This can lead to automation side effects in repos you didn’t intend to modify.

3. **Rules bleed between repos**
    - Shared rules are injected into **every** project using the symlink, even if they are repo‑specific.
    - This can silently change model behavior or tool approvals.

4. **File watchers and reload storms**
    - Multiple projects watching the same directory can cause redundant reloads and noisy logs.

### Recommended patterns (safe + predictable)

- **Prefer global config for shared data**:
    - Use `~/.aider-desk/agents`, `~/.aider-desk/commands`, `~/.aider-desk/hooks`, and `~/.aider-desk/rules` for shared configuration.

- **If you must symlink, do it selectively**:
    - Symlink **only** the directories you want to share, not the entire `.aider-desk/`.
    - Example safe split:
        - Shared: `.aider-desk/commands`, `.aider-desk/hooks`, `.aider-desk/rules`
        - Local: `.aider-desk/tasks`

- **Keep `tasks/` local**:
    - This avoids cross‑project history, keeps per‑repo state clean, and prevents collisions.

- **Document the shared intent**:
    - Add a short `README.md` in the shared directory explaining which projects consume it and why.

---

## Diagram: How `.aider-desk/` Fits Together

### Structure at a glance
```
<project>/
└── .aider-desk/
    ├── agents/             # Project-level agent profiles (optional overrides)
    │   ├── rails-refactor/
    │   │   ├── config.json
    │   │   └── rules/
    │   │       ├── coding-standards.md
    │   │       └── architecture.md
    │   └── rails-ui/
    │       ├── config.json
    │       └── rules/
    ├── hooks/              # Project hook modules (JS)
    │   ├── 01-guardrails.js
    │   └── 02-metrics.js
    ├── commands/           # Project command templates (MD)
    │   ├── review/
    │   │   └── security.md
    │   └── run/
    │       └── smoke.md
    ├── rules/              # Project rules (MD)
    │   ├── invariants.md
    │   └── architecture.md
    └── tasks/              # Per-task state (generated)
        └── <task-id>/
            ├── settings.json
            ├── context.json
            └── .aider.chat.history.md
```

### Event flow (what loads when)
```
User prompt
  └─> Agent profile selected
        ├─> rules injected (global + AGENTS.md + project + profile rules)
        ├─> commands loaded (global then project overrides)
        ├─> hooks loaded (global then project)
        └─> task state persisted under .aider-desk/tasks/<task-id>
```

---

## Best‑Practice Layout (Team Agents + Hook Strategy)

This layout mirrors a common Rails team setup with **four profiles** and **two hook tiers** (guardrails + telemetry). It assumes:
- **Agent profiles**: `rails-greenfield`, `rails-refactor`, `rails-debug`, `rails-ui`
- **Hook strategy**: pre‑flight guardrails + post‑prompt metrics

### Recommended directory layout
```
<project>/
└── .aider-desk/
    ├── agents/
    │   ├── rails-greenfield/
    │   │   ├── config.json
    │   │   └── rules/
    │   ├── rails-refactor/
    │   │   ├── config.json
    │   │   └── rules/
    │   ├── rails-debug/
    │   │   ├── config.json
    │   │   └── rules/
    │   └── rails-ui/
    │       ├── config.json
    │       └── rules/
    ├── hooks/
    │   ├── 01-guardrails.js
    │   ├── 02-cost-metrics.js
    │   └── 03-log-artifacts.js
    ├── commands/
    │   ├── review/security.md
    │   ├── review/perf.md
    │   └── run/smoke.md
    └── rules/
        ├── invariants.md
        ├── architecture.md
        └── testing-policy.md
```

### Sample hook intent (high‑signal, low‑risk)
`hooks/01-guardrails.js` (pre‑flight): block dangerous operations or enforce policies.
```
module.exports = {
  onHandleApproval(event) {
    if (event?.key?.includes('power---bash') && /\brm\s+-rf\b/.test(event.text)) {
      return false; // block destructive commands
    }
  },
};
```

`hooks/02-cost-metrics.js` (post‑prompt): log model usage and elapsed time.
```
module.exports = {
  onPromptFinished(event, context) {
    const summary = {
      project: context.project.baseDir,
      responses: event.responses?.length ?? 0,
      timestamp: new Date().toISOString(),
    };
    context.logger.info('[metrics] prompt-finished', summary);
  },
};
```

### Sample command template
`commands/review/security.md`
```
---
description: Focused security review of recent changes
arguments:
  - name: scope
    description: e.g. "auth", "payments", or "all"
    required: false
---
Review the recent diff with a security lens. Scope: {{1}}
- identify input validation gaps
- check authz boundaries
- flag secrets, tokens, or unsafe shell usage
```

### Agent-to-task mapping (example)
- **`rails-greenfield`**: new endpoints, new service classes, net‑new features
- **`rails-refactor`**: existing flows, migrations, integration glue
- **`rails-debug`**: failing tests, reproduction‑first investigations
- **`rails-ui`**: views/components, Tailwind/DaisyUI, Stimulus wiring

### Notes on maintainability
- Keep **project rules** minimal; push reusable rules into profile `rules/`.
- Keep hooks **idempotent** and avoid writing to the repo by default.
- Avoid cross‑project leakage by keeping `tasks/` local even if sharing hooks/commands.

---

## Quick Reference

| Directory | Purpose | Scope | Override/Order |
|---|---|---|---|
| `hooks/` | JS hook automation | Global + Project | Global hooks run before project hooks |
| `commands/` | Custom prompt templates | Global + Project | Project commands override by name |
| `rules/` | Read‑only prompt context | Global + Project + AGENTS.md + Agent rules | All are merged into context |
| `tasks/` | Per‑task settings/context/history | Project | Not shared across projects by design |

If you want, I can also add a diagram or a “best‑practice layout” section that matches your team’s agent profiles and hook strategy.
