Here is a **new, tailored version** of the Junie guidelines, specifically rewritten and adapted for the **agent-forge** project (https://github.com/ericsmith66/agent-forge).

This version removes all references to the previous/nextgen-plaid context (e.g., net worth components, Plaid integration) and replaces them with agent-forge-specific rules. It preserves the strong safety rails, communication discipline, and Rails conventions while adding explicit support for our meta-agent system: self-improvement loop, multiple LLM backends (Claude, Grok, Ollama), GitHub API usage, agent orchestration, and knowledge_base reliance.

**Recommended file path**: `.junie/guidelines.md`  
(Replace the existing file or create it if not yet present — commit with a message like "Adapt Junie guidelines for agent-forge meta-framework".)

```markdown
# Junie Guidelines — agent-forge

These are **project-specific operating rules** for Junie/AI assistants (Claude, Grok, Ollama, etc.) working in this repository.

They are written to be:
- **Actionable** (clear do/don’t)
- **Safe** (avoid destructive commands, repo corruption)
- **Consistent** (match Rails + agent-forge conventions)

agent-forge is the **meta-framework** that AI coding agents use to build and improve itself, then bootstrap other applications. Primary stack: Ruby on Rails 7+.

---

## 1) Repo overview (what this is)

- Ruby on Rails 7+ application (API + web for agent orchestration/dashboard).
- UI work frequently uses:
  - Hotwire/Turbo (`turbo_frame_tag`, `turbo_stream`)
  - ViewComponent (`app/components/agents/`, `app/components/shared/`)
  - DaisyUI + Tailwind CSS for styling
- Tests use **Minitest** (`test/` folder), including `ViewComponent::TestCase` and system tests with Capybara.
- Persistent knowledge & planning live in `knowledge_base/`:
  - `core-agent-instructions.md` (global agent rules)
  - Templates for Epics/PRDs/status trackers
  - Active epics, PRDs, implementation logs
- Agents interact with repo via:
  - Local file read/write
  - Git operations (safe only)
  - Future: GitHub API for PR creation/review

---

## 2) Critical communication rule (prevents loops)

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

## 3) Safety rails (protect the forge)

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

## 4) Implementation conventions

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

## 5) Testing expectations

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

## 6) Documentation & knowledge base workflow

### Always reference knowledge_base first
- Read `knowledge_base/core-agent-instructions.md` on every major task.
- Then `.junie/guidelines.md` (this file).
- Then relevant Epic/PRD + `*-IMPLEMENTATION-STATUS.md`.

### Use templates
- Create new Epics/PRDs from `knowledge_base/templates/`
  - Epic overview: `0000-EPIC-OVERVIEW-template.md`
  - Status tracker: `0001-IMPLEMENTATION-STATUS-template.md`
  - PRD: `PRD-template.md`

### Self-improvement rule
- When improving agents, tools, or architecture:
  - Also propose updates to this file, `core-agent-instructions.md`, or templates.
  - Use the Epic/PRD → implementation → review loop.

---

Last updated: [Insert commit date]  
Project: agent-forge — self-building AI agent framework
```

### Next Steps
1. **Commit this file** to `.junie/guidelines.md` (or update the existing one).
2. **Verify** the knowledge_base structure is set up (templates/, epics/, etc.) — if not, we can create an Epic for it.
3. Once in place, all future Epics/PRDs will require agents to load **both** this file and `core-agent-instructions.md` at the start of every task.

Does this version capture what you want? Any sections to expand (e.g., more on Ollama/local model handling, agent handoff protocols, error recovery)? Or shall we move to drafting **Epic 0: Initialize Guidelines & Knowledge Layer** to get the full structure committed? Let's keep forging! 🚀