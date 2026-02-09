# Junie Guidelines — agent-forge

Updated 2026-02-08: Added Git & Sub-Project Structure Rules.

These are **project-specific operating rules** for Junie/AI assistants (Claude, Grok, Ollama, etc.) working in this repository.

They are written to be:
- **Actionable** (clear do/don’t)
- **Safe** (avoid destructive commands, repo corruption)
- **Consistent** (match Rails + agent-forge conventions)

agent-forge is the **meta-framework** that AI coding agents use to build and improve itself, then bootstrap other applications. Primary stack: Ruby on Rails 7+.

---

## 1) Repo overview (what this is)

- Ruby on Rails 7+ application (API + web for agent orchestration/dashboard).
- server is running on an m3ultra with 128gb ram and starts on port 3017 its IP is 192.168.4.200
- UI work frequently uses:
  - Hotwire/Turbo (`turbo_frame_tag`, `turbo_stream`)
  - ViewComponent (`app/components/agents/`, `app/components/shared/`)
  - DaisyUI + Tailwind CSS for styling
- Tests use **Minitest** (`test/` folder), including `ViewComponent::TestCase` and system tests with Capybara.
- Persistent knowledge & planning live in `knowledge_base/`:
  - `ai-instructions/grok-instructions.md` (global agent rules)
  - `ai-instructions/junie-log-requirement.md` (logging standards)
  - Templates for Epics/PRDs/status trackers
  - Active epics, PRDs, implementation logs
- Agents interact with repo via:
  - Local file read/write
  - Git operations (safe only)
  - Future: GitHub API for PR creation/review

---

## 2) Git & Sub-Project Structure Rules

All sub-projects managed by agent-forge live under the `projects/` directory (e.g. `projects/eureka-homekit-rebuild`, `projects/aider-desk-test`, etc.).

### Rules:

1. **Independent git repositories**  
   - Every sub-project folder is its own independent git repository (has its own `.git/` directory).  
   - Never nest git repositories inside agent-forge's root repo.  
   - The parent agent-forge repository must **never** track files inside `projects/`.

2. **Root .gitignore update**  
   Add or update the following lines in the **root** `.gitignore` of agent-forge:
   ```
   # Ignore all sub-projects — they are separate git repositories
   projects/*
   !projects/.gitignore
   !projects/README.md
   ```
   This prevents agent-forge from committing sub-project files accidentally.

3. **Per-project .gitignore**  
   - Each sub-project must have its own normal `.gitignore` (e.g. Rails default: ignore `tmp/`, `log/`, `vendor/`, `.env`, etc.).  
   - Do not override or remove any standard Rails ignores.

4. **Project creation / initialization**  
   When creating a new sub-project (via chat command, UI, or agent action):
   - Create the folder: `projects/<project-name>`
   - Run inside it:
     ```bash
     git init
     # Add at least one file (e.g. README.md)
     echo "# <project-name> - Created by agent-forge" > README.md
     git add README.md
     git commit -m "Initial commit – created by agent-forge"
     ```
   - Optional: If GitHub integration is enabled, push to remote:
     ```bash
     gh repo create ericsmith66/<project-name> --private --source=. --remote=origin
     git push -u origin main
     ```

5. **Safety rails for git operations**  
   - **Never** run `git commit`, `git push`, `git add .`, or destructive git commands without explicit user confirmation (e.g. "/commit" command in chat).  
   - **Never** modify the root agent-forge .gitignore or .git from inside a sub-project task.  
   - When editing files in a sub-project, always operate within the projectDir scope.  
   - Prefer AiderDesk / Aider for code changes — it handles git diffs and commits safely (preview mode only until approved).  
   - Log all git-related actions in the task log and implementation status.

6. **Existing projects (e.g. cloning eureka-homekit)**  
   - Clone directly into projects/:
     ```bash
     cd projects
     git clone https://github.com/ericsmith66/eureka-homekit.git eureka-homekit-rebuild
     ```
   - Do not use git submodules unless explicitly requested.

---

## 3) Critical communication rule (prevents loops)

Junie sessions may show timeout/keep-alive prompts.

### Interpretation rule
- A bare message like `continue` (or similar) is **keep-alive only**.
- **Do not** re-run tests, re-check status, or repeat updates on bare `continue`.
- When task is complete and no further action needed:
  - Post **exactly once**:
    ```
    STATUS: DONE — awaiting review (no commit yet)
    ```
  - Then stop / quit the task.

---

## 4) Safety rails (protect the forge)

### Database safety (high priority)
- **Never** run destructive DB commands without explicit human confirmation:
  - `db:drop`, `db:reset`, `db:truncate`, `db:migrate:reset`, etc.
- Prefer test environment scoping:
  - `RAILS_ENV=test bin/rails db:migrate`
  - `RAILS_ENV=test bin/rails test`
- If a command could affect development DB, **ask first**.

### Git & repo safety
- **Do not** `git commit`, `git push`, or generate commits/PRs unless explicitly instructed.
- Avoid unrelated diffs (whitespace, formatting only).
- When proposing code changes:
  - Output full file paths + diffs
  - Use clear commit message suggestions
  - Wait for human approval before any git action.

### LLM & agent safety
- Never fabricate API keys, tokens, or credentials.
- When switching LLMs (Claude → Grok → Ollama), log the switch and reason.
- Do not run infinite agent loops without human oversight.

---

## 5) Implementation conventions

### Agent & orchestration patterns
- Prefer explicit agent roles (Coder, Planner, Reviewer, Orchestrator).
- Use `lib/agents/` or `app/services/agents/` for core logic.
- Implement LLM dispatcher early (support Claude, Grok/xAI API, Ollama/local).
- Use file-based memory first → later vector DB/Rails model for long-term recall.

### Components & UI
- Prefer ViewComponents for agent dashboards, task views, logs.
- Mirror patterns in `app/components/` once established.
- Defensive data handling: tolerate missing keys, empty states, log errors (`Rails.logger`).

### Styling
- DaisyUI + Tailwind utility classes.
- Mobile-first responsive design.

### Accessibility
- Meaningful headings, labels, `aria-*` attributes.
- Non-visual fallbacks for data-heavy views (tables alongside charts).

---

## 6) Testing expectations

### Default test stack
- **Minitest** only (no RSpec unless requested).

### What to add
- New services/agents → unit tests (`test/services/`, `test/lib/`)
- New ViewComponents → `test/components/...`
- Integration/wiring → `test/integration/...`
- End-to-end agent flows → system/smoke tests `test/system/`

### How to run
- Smallest relevant set first:
  - `bin/rails test test/lib/agents/...`
  - `bin/rails test test/components/...`
  - Full suite only when needed: `bin/rails test`

Log test results in status trackers or task output.

---

## 7) Documentation & knowledge base workflow

### Always reference knowledge_base first
- Read `knowledge_base/ai-instructions/grok-instructions.md` on every major task.
- Then `knowledge_base/ai-instructions/junie-log-requirement.md` for logging rules.
- Then `.junie/guidelines.md` (this file).
- Then relevant Epic/PRD + `*-IMPLEMENTATION-STATUS.md`.

### Use templates
- Create new Epics/PRDs from `knowledge_base/templates/`
  - Epic overview: `0000-EPIC-OVERVIEW-template.md`
  - Status tracker: `0001-IMPLEMENTATION-STATUS-template.md`
  - PRD: `PRD-template.md`

### Self-improvement rule
- When improving agents, tools, or architecture:
  - Also propose updates to this file, `ai-instructions/grok-instructions.md`, or templates.
  - Use the Epic/PRD → implementation → review loop.

---

Last updated: 2026-02-09  
Project: agent-forge — self-building AI agent framework
