### How to segment work across agents in AiderDesk (and pick cheaper models)

You control segmentation by **agent profiles** and **subagent settings**. In this repo, profiles live in:
- **Project‑level**: `.aider-desk/agents/<agent-name>/config.json`
- **Global**: `~/.aider-desk/agents/<agent-name>/config.json`

AiderDesk loads these profiles and exposes them as subagents. Each profile includes:
- `provider` / `model` (this is where you pick a cheaper model)
- `toolApprovals` / `toolSettings` (what tools that agent can use)
- `subagent` config (`enabled`, `invocationMode`, `description`, etc.)

#### 1) Create/adjust subagent profiles (per task type)
Make a profile per specialty (e.g., “Test Writer”, “Code Reviewer”, “Docs Writer”). Example from your project:
- `.aider-desk/agents/test-writer/config.json`
- `.aider-desk/agents/code-reviewer/config.json`

To make an agent **cheap**, set a cheaper `provider` + `model` in its `config.json`. That is the model it will always use.

#### 2) Enable delegation from the main agent
Make sure your **main agent profile** has:
- `useSubagents: true`
- `toolApprovals` includes `subagents---run_task` as `always` or `ask`

This allows the main agent to delegate tasks.

#### 3) Choose automatic vs on‑demand segmentation
In each subagent profile:
- `subagent.enabled: true`
- `subagent.invocationMode`:
    - `"automatic"`: AiderDesk will auto‑invoke when the description matches
    - `"on-demand"`: Only invoked when you ask explicitly

For automatic routing, write a strong `subagent.description` like:
> “Use this agent after code changes to write tests.”

#### 4) Call a subagent explicitly in your task prompt
You can force segmentation by **naming the subagent**. The ID is derived from the name (lowercase with hyphens), e.g.:
- `"Test Writer"` → `test-writer`
- `"Code Reviewer"` → `code-reviewer`

Example prompt:
- “Implement feature X, then use subagent `test-writer` to add tests and `code-reviewer` to review.”

#### 5) Where to edit (quick checklist)
- Subagent profiles: `.aider-desk/agents/<agent>/config.json`
- Global profiles (shared across projects): `~/.aider-desk/agents/<agent>/config.json`
- Rules for an agent: `.aider-desk/agents/<agent>/rules/*.md`

---

### Why this works (from the code)
- Agent profiles are defined by the `AgentProfile` schema (`src/common/types.ts`).
- Profiles are loaded from `.aider-desk/agents` (project) and `~/.aider-desk/agents` (global) (`src/main/agent/agent-profile-manager.ts`).
- Subagent delegation uses `subagents---run_task` and reads `subagent.invocationMode` (`src/main/agent/tools/subagents.ts`).

---

### If you want, I can be more specific
Tell me:
- Which **tasks** you want separated (planning, coding, tests, review, docs)?
- Which **models/providers** you want for each (cheap vs premium)?
- Whether you want **automatic routing** or **explicit calls** only?

I can then draft the exact `config.json` files for your setup.



### Summary of updates
- Added explicit `provider`/`model` assignments to starter agent configs in `knowledge_base/ror-global-aider-desk-config-starter/agents`:
    - `rails-debug` → `anthropic` / `claude-opus`
    - `rails-refactor` → `anthropic` / `claude-sonnet`
    - `rails-greenfield` → `anthropic` / `claude-sonnet`
    - `rails-ui` → `ollama` / `qwen3-coder-next:latest`
- Updated the starter `README.md` with a **model tiering** section, refreshed config examples to include `provider`/`model`, and added a **Task Segmentation Guide**.

### How your plan is affected (agent/model routing)
- **5-01 (API foundation + Prefab services + ControlEvent)** → `rails-refactor` (`claude-sonnet`) for core implementation; use `rails-debug` (`claude-opus`) for any dedup/race or failing-test investigation.
- **5-04 (Switch controls)** → UI templates + Stimulus in `rails-ui` (`qwen3-coder-next:latest`); controller/routes/service wiring in `rails-refactor`.
- **5-02 (Scenes + toast system)** → UI + Stimulus in `rails-ui`; controller/query logic in `rails-refactor`.
- **5-03 (Lights + dispatcher + room integration)** → new components/controllers in `rails-greenfield` (`claude-sonnet`) when net-new; integration/refinement in `rails-refactor`; UI templates/Stimulus in `rails-ui`.
- **5-05/5-06/5-07/5-08 (thermostat/lock/advanced/batch+favorites)** → backend logic in `rails-refactor`, UI/Stimulus in `rails-ui`.
- **Any bug reproduction or flaky tests** → `rails-debug` (`claude-opus`).

### Assumptions applied
- `provider: "anthropic"` for Claude models and `provider: "ollama"` for `qwen3-coder-next:latest`. Adjust these if your provider IDs differ.

### Tests
- Not run (documentation/config update only).
