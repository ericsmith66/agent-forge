# PRD-01: AiderDesk Ruby API Helper Library

> **Status:** Draft
> **Created:** 2026-02-08
> **Source docs:** `aider_api.md` (endpoint reference), `api_test.rb` (proof-of-concept)

---

## 1. Overview

Build a single-file Ruby library (`aider_desk_api.rb`) that provides a clean, idiomatic Ruby interface to **every** AiderDesk REST API endpoint. The library uses only Ruby stdlib (`net/http`, `json`, `uri`) — no external gems required.

A companion CLI runner (`aider_cli.rb`) will provide a command-line interface for quick interactions.

---

## 2. Goals

| # | Goal | Success Criteria |
|---|------|-----------------|
| G1 | Full API coverage | Every endpoint in `aider_api.md` has a corresponding Ruby method |
| G2 | Zero external dependencies | Uses only Ruby stdlib (`net/http`, `json`, `uri`) |
| G3 | Idiomatic Ruby | Class-based client, keyword arguments, snake_case methods, structured responses |
| G4 | Reusable | Importable via `require_relative` from any script in the project |
| G5 | Configurable | Base URL, port, auth credentials, project dir all configurable at init or via ENV |
| G6 | Async-aware | Built-in polling helper for prompt execution (run-prompt → poll for completion) |
| G7 | CLI companion | `aider_cli.rb` provides quick command-line access to common operations |

---

## 3. Architecture

### 3.1 File Structure

```
project-root/
├── lib/
│   └── aider_desk_api.rb    # Main library (single file)
├── aider_cli.rb              # CLI runner
├── api_test.rb               # Existing test script (will be refactored to use the library)
├── aider_api.md              # Endpoint reference (existing)
└── prd-01-aider.md           # This PRD
```

### 3.2 Class Design

```ruby
module AiderDesk
  class Client
    # Core transport
    # Configuration
    # Endpoint modules mixed in
  end

  class Response
    # Wraps Net::HTTP response
    # Provides .success?, .data, .status, .body, .error
  end

  class PromptRunner
    # Handles async prompt execution + polling
  end
end
```

---

## 4. Detailed Design

### 4.1 `AiderDesk::Client` — Initialization & Configuration

```ruby
client = AiderDesk::Client.new(
  base_url: "http://localhost:24337",  # or ENV['AIDER_BASE_URL']
  username: "admin",                    # or ENV['AIDER_USERNAME']
  password: "booberry",                 # or ENV['AIDER_PASSWORD']
  project_dir: "/path/to/project"      # or ENV['AIDER_PROJECT_DIR']
)
```

**Configuration precedence:** explicit argument → ENV variable → default value

| Config | ENV Variable | Default |
|--------|-------------|---------|
| `base_url` | `AIDER_BASE_URL` | `http://localhost:24337` |
| `username` | `AIDER_USERNAME` | `nil` (no auth) |
| `password` | `AIDER_PASSWORD` | `nil` (no auth) |
| `project_dir` | `AIDER_PROJECT_DIR` | `nil` (must be set per-call or at init) |

### 4.2 `AiderDesk::Response` — Structured Response Wrapper

Every method returns an `AiderDesk::Response`:

```ruby
response = client.get_settings
response.success?   # => true
response.status      # => 200
response.data        # => parsed JSON hash
response.body        # => raw response body string
response.error       # => nil or error message string
```

### 4.3 Core Transport Layer

The `Client` will have private methods for HTTP transport:

| Method | Description |
|--------|-------------|
| `#get(path, params: {})` | GET with optional query params |
| `#post(path, body: {})` | POST with JSON body |
| `#patch(path, body: {})` | PATCH with JSON body |
| `#delete(path, body: {})` | DELETE with JSON body |

All transport methods handle:
- Basic auth injection (when credentials present)
- JSON serialization/deserialization
- URI construction with query params
- Wrapping into `AiderDesk::Response`
- Connection error handling (rescue → Response with error)

---

## 5. API Method Catalog

Every public method auto-injects `project_dir:` from the client default when not explicitly provided. Methods requiring `task_id` always take it as the first positional or keyword argument.

### 5.1 System

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `get_env_var(key:, base_dir: nil)` | GET | `/api/system/env-var` | `key`, `baseDir` |

### 5.2 Settings

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `get_settings` | GET | `/api/settings` | — |
| `update_settings(settings)` | POST | `/api/settings` | settings hash |
| `get_recent_projects` | GET | `/api/settings/recent-projects` | — |
| `add_recent_project(project_dir:)` | POST | `/api/settings/add-recent-project` | `projectDir` |
| `remove_recent_project(project_dir:)` | POST | `/api/settings/remove-recent-project` | `projectDir` |
| `set_zoom(level:)` | POST | `/api/settings/zoom` | `level` (0.5–3.0) |
| `get_versions(force_refresh: false)` | GET | `/api/versions` | `forceRefresh` |
| `download_latest` | POST | `/api/download-latest` | — |
| `get_release_notes` | GET | `/api/release-notes` | — |
| `clear_release_notes` | POST | `/api/clear-release-notes` | — |
| `get_os` | GET | `/api/os` | — |

### 5.3 Prompts

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `run_prompt(task_id:, prompt:, mode: "agent")` | POST | `/api/run-prompt` | `projectDir`, `taskId`, `prompt`, `mode` |
| `save_prompt(task_id:, prompt:)` | POST | `/api/save-prompt` | `projectDir`, `taskId`, `prompt` |

### 5.4 Context Files

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `add_context_file(task_id:, path:, read_only: false)` | POST | `/api/add-context-file` | `projectDir`, `taskId`, `path`, `readOnly` |
| `drop_context_file(task_id:, path:)` | POST | `/api/drop-context-file` | `projectDir`, `taskId`, `path` |
| `get_context_files(task_id:)` | POST | `/api/get-context-files` | `projectDir`, `taskId` |
| `get_addable_files(task_id:, search_regex: nil)` | POST | `/api/get-addable-files` | `projectDir`, `taskId`, `searchRegex` |
| `get_all_files(task_id:, use_git: false)` | POST | `/api/get-all-files` | `projectDir`, `taskId`, `useGit` |

### 5.5 Custom Commands

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `get_custom_commands(project_dir:)` | GET | `/api/project/custom-commands` | `projectDir` (query) |
| `run_custom_command(task_id:, command_name:, args: [], mode: "agent")` | POST | `/api/project/custom-commands` | `projectDir`, `taskId`, `commandName`, `args`, `mode` |

### 5.6 Projects

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `get_projects` | GET | `/api/projects` | — |
| `get_input_history(project_dir:)` | GET | `/api/project/input-history` | `projectDir` (query) |
| `add_open_project(project_dir:)` | POST | `/api/project/add-open` | `projectDir` |
| `remove_open_project(project_dir:)` | POST | `/api/project/remove-open` | `projectDir` |
| `set_active_project(project_dir:)` | POST | `/api/project/set-active` | `projectDir` |
| `restart_project(project_dir:)` | POST | `/api/project/restart` | `projectDir` |
| `start_project(project_dir:)` | POST | `/api/project/start` | `projectDir` |
| `stop_project(project_dir:)` | POST | `/api/project/stop` | `projectDir` |
| `update_project_order(project_dirs:)` | POST | `/api/project/update-order` | `projectDirs` |
| `get_project_settings(project_dir:)` | GET | `/api/project/settings` | `projectDir` (query) |
| `update_project_settings(project_dir:, **settings)` | PATCH | `/api/project/settings` | `projectDir` + partial settings |
| `validate_path(path:)` | POST | `/api/project/validate-path` | `projectDir`, `path` |
| `is_project_path(path:)` | POST | `/api/project/is-project-path` | `path` |
| `file_suggestions(current_path:, directories_only: false)` | POST | `/api/project/file-suggestions` | `currentPath`, `directoriesOnly` |
| `paste_image(task_id:, base64_image_data: nil)` | POST | `/api/project/paste-image` | `projectDir`, `taskId`, `base64ImageData` |
| `apply_edits(task_id:, edits:)` | POST | `/api/project/apply-edits` | `projectDir`, `taskId`, `edits` |
| `run_command(task_id:, command:)` | POST | `/api/project/run-command` | `projectDir`, `taskId`, `command` |
| `init_rules(task_id:)` | POST | `/api/project/init-rules` | `projectDir`, `taskId` |
| `scrape_web(task_id:, url:, file_path: nil)` | POST | `/api/project/scrape-web` | `projectDir`, `taskId`, `url`, `filePath` |

### 5.7 Tasks

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `create_task(name: nil, parent_id: nil)` | POST | `/api/project/tasks/new` | `projectDir`, `name`, `parentId` |
| `update_task(task_id:, updates:)` | POST | `/api/project/tasks` | `projectDir`, `id`, `updates` |
| `load_task(task_id:)` | POST | `/api/project/tasks/load` | `projectDir`, `id` |
| `list_tasks(project_dir:)` | GET | `/api/project/tasks` | `projectDir` (query) |
| `delete_task(task_id:)` | POST | `/api/project/tasks/delete` | `projectDir`, `id` |
| `duplicate_task(task_id:)` | POST | `/api/project/tasks/duplicate` | `projectDir`, `taskId` |
| `fork_task(task_id:, message_id:)` | POST | `/api/project/tasks/fork` | `projectDir`, `taskId`, `messageId` |
| `reset_task(task_id:)` | POST | `/api/project/tasks/reset` | `projectDir`, `taskId` |
| `export_task_markdown(task_id:)` | POST | `/api/project/tasks/export-markdown` | `projectDir`, `taskId` |
| `resume_task(task_id:)` | POST | `/api/project/resume-task` | `projectDir`, `taskId` |

### 5.8 Messages

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `remove_last_message(task_id:)` | POST | `/api/project/remove-last-message` | `projectDir`, `taskId` |
| `remove_message(task_id:, message_id:)` | DELETE | `/api/project/remove-message` | `projectDir`, `taskId`, `messageId` |
| `remove_messages_up_to(task_id:, message_id:)` | DELETE | `/api/project/remove-messages-up-to` | `projectDir`, `taskId`, `messageId` |

### 5.9 Conversation

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `redo_prompt(task_id:, mode:, updated_prompt: nil)` | POST | `/api/project/redo-prompt` | `projectDir`, `taskId`, `mode`, `updatedPrompt` |
| `compact_conversation(task_id:, mode:, custom_instructions: nil)` | POST | `/api/project/compact-conversation` | `projectDir`, `taskId`, `mode`, `customInstructions` |
| `handoff_conversation(task_id:, focus: nil)` | POST | `/api/project/handoff-conversation` | `projectDir`, `taskId`, `focus` |
| `interrupt(task_id:)` | POST | `/api/project/interrupt` | `projectDir`, `taskId` |
| `clear_context(task_id:)` | POST | `/api/project/clear-context` | `projectDir`, `taskId` |
| `answer_question(task_id:, answer:)` | POST | `/api/project/answer-question` | `projectDir`, `taskId`, `answer` |

### 5.10 Model Settings

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `set_main_model(task_id:, main_model:)` | POST | `/api/project/settings/main-model` | `projectDir`, `taskId`, `mainModel` |
| `set_weak_model(task_id:, weak_model:)` | POST | `/api/project/settings/weak-model` | `projectDir`, `taskId`, `weakModel` |
| `set_architect_model(task_id:, architect_model:)` | POST | `/api/project/settings/architect-model` | `projectDir`, `taskId`, `architectModel` |
| `set_edit_formats(edit_formats:)` | POST | `/api/project/settings/edit-formats` | `projectDir`, `editFormats` |

### 5.11 Worktrees

| Method | HTTP | Endpoint | Parameters |
|--------|------|----------|------------|
| `worktree_merge_to_main(task_id:, squash: true, target_branch: nil, commit_message: nil)` | POST | `/api/project/worktree/merge-to-main` | `projectDir`, `taskId`, `squash`, `targetBranch`, `commitMessage` |
| `worktree_apply_uncommitted(task_id:, target_branch: nil)` | POST | `/api/project/worktree/apply-uncommitted` | `projectDir`, `taskId`, `targetBranch` |
| `worktree_revert_last_merge(task_id:)` | POST | `/api/project/worktree/revert-last-merge` | `projectDir`, `taskId` |
| `worktree_branches(project_dir:)` | GET | `/api/project/worktree/branches` | `projectDir` (query) |
| `worktree_status(task_id:, target_branch: nil)` | GET | `/api/project/worktree/status` | `projectDir`, `taskId`, `targetBranch` (query) |
| `worktree_rebase_from_branch(task_id:, from_branch: nil)` | POST | `/api/project/worktree/rebase-from-branch` | `projectDir`, `taskId`, `fromBranch` |
| `worktree_abort_rebase(task_id:)` | POST | `/api/project/worktree/abort-rebase` | `projectDir`, `taskId` |
| `worktree_continue_rebase(task_id:)` | POST | `/api/project/worktree/continue-rebase` | `projectDir`, `taskId` |
| `worktree_resolve_conflicts(task_id:)` | POST | `/api/project/worktree/resolve-conflicts-with-agent` | `projectDir`, `taskId` |

---

## 6. High-Level Convenience Methods

These combine multiple API calls for common workflows:

| Method | Description |
|--------|-------------|
| `run_prompt_and_wait(task_id:, prompt:, mode:, timeout: 120, poll_interval: 5, &block)` | Runs a prompt, polls `load_task` until `response-completed` detected or timeout. Yields new messages to optional block. Returns final task data. |
| `create_task_and_run(prompt:, name: nil, mode: "agent", timeout: 120)` | Creates a new task, runs a prompt, waits for completion. Returns `{ task_id:, messages:, response: }`. |
| `health_check` | Calls `get_settings`, returns `true`/`false`. |

---

## 7. CLI Companion (`aider_cli.rb`)

A lightweight script for terminal usage:

```bash
# Health check
ruby aider_cli.rb health

# List projects
ruby aider_cli.rb projects

# Get settings
ruby aider_cli.rb settings

# Create task
ruby aider_cli.rb task:create --name "My Task"

# List tasks
ruby aider_cli.rb task:list

# Run prompt (blocks until complete)
ruby aider_cli.rb prompt --task TASK_ID --mode agent "Fix the bug in auth.rb"

# Add context file
ruby aider_cli.rb context:add --task TASK_ID --path src/main.rb

# List context files
ruby aider_cli.rb context:list --task TASK_ID

# Set model
ruby aider_cli.rb model:set --task TASK_ID --model ollama/llama3.1:8b

# Interrupt running task
ruby aider_cli.rb interrupt --task TASK_ID
```

**Configuration via ENV or `~/.aider_cli.yml`:**

```yaml
base_url: http://localhost:24337
username: admin
password: booberry
project_dir: /Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild
default_model: ollama/llama3.1:8b
```

---

## 8. Implementation Plan

### Phase 1: Core Library (`lib/aider_desk_api.rb`)

| Step | Task | Estimated LOC |
|------|------|---------------|
| 1.1 | `AiderDesk::Response` class | ~30 |
| 1.2 | `AiderDesk::Client` — init, config, transport (`get`/`post`/`patch`/`delete`) | ~80 |
| 1.3 | System & Settings methods (§5.1, §5.2) | ~60 |
| 1.4 | Prompt methods (§5.3) | ~20 |
| 1.5 | Context file methods (§5.4) | ~40 |
| 1.6 | Custom command methods (§5.5) | ~20 |
| 1.7 | Project methods (§5.6) | ~100 |
| 1.8 | Task methods (§5.7) | ~60 |
| 1.9 | Message methods (§5.8) | ~25 |
| 1.10 | Conversation methods (§5.9) | ~45 |
| 1.11 | Model settings methods (§5.10) | ~30 |
| 1.12 | Worktree methods (§5.11) | ~70 |
| 1.13 | High-level convenience methods (§6) | ~60 |

**Estimated total:** ~640 LOC

### Phase 2: CLI Runner (`aider_cli.rb`)

| Step | Task | Estimated LOC |
|------|------|---------------|
| 2.1 | Argument parsing & config loading | ~50 |
| 2.2 | Command dispatch (health, projects, settings) | ~30 |
| 2.3 | Task commands (create, list, delete, load) | ~40 |
| 2.4 | Prompt command (run + wait with live output) | ~40 |
| 2.5 | Context commands (add, drop, list) | ~30 |
| 2.6 | Model commands | ~20 |
| 2.7 | Pretty output formatting (JSON + table) | ~30 |

**Estimated total:** ~240 LOC

### Phase 3: Refactor & Validate

| Step | Task |
|------|------|
| 3.1 | Refactor `api_test.rb` to use the new library |
| 3.2 | Manual smoke test: each endpoint category against a running AiderDesk instance |
| 3.3 | Document any endpoint discrepancies found during testing |

---

## 9. Conventions & Patterns

### 9.1 Naming

- Ruby methods: `snake_case` (e.g., `create_task`, `run_prompt`)
- JSON keys sent to API: `camelCase` (e.g., `projectDir`, `taskId`)
- Internal conversion: a private `#camelize` helper converts Ruby keyword args to API JSON keys

### 9.2 project_dir Injection

Methods that require `projectDir` accept an optional `project_dir:` keyword. If not provided, they fall back to `@project_dir` set at client initialization. Raises `ArgumentError` if neither is set.

### 9.3 Error Handling

- Network errors → `Response` with `success? == false`, `error` set to exception message
- HTTP 4xx/5xx → `Response` with `success? == false`, `data` contains parsed error body if JSON
- No exceptions raised for API errors (caller decides how to handle)
- Optional `Client.new(..., raise_on_error: true)` mode that raises `AiderDesk::ApiError` on non-2xx

### 9.4 Logging

- Optional `logger:` parameter on `Client.new`
- Defaults to `Logger.new($stdout, level: Logger::WARN)`
- Debug level logs all requests/responses

---

## 10. Dependencies

- **Runtime:** Ruby stdlib only (`net/http`, `json`, `uri`, `logger`, `yaml`)
- **Ruby version:** >= 2.7 (for keyword argument syntax and `..` range)
- **No Gemfile required**

---

## 11. Out of Scope (for now)

- WebSocket/SSE streaming for real-time message updates
- Thread safety / connection pooling
- Retry logic with exponential backoff
- Gem packaging / publishing
- Automated test suite (RSpec/Minitest)

---

## 12. Open Questions

| # | Question | Proposed Answer |
|---|----------|-----------------|
| Q1 | Should the CLI support YAML config or just ENV vars? | Both — YAML for convenience, ENV for CI/automation |
| Q2 | Should `export_task_markdown` return raw markdown string or save to file? | Return the raw body; CLI can pipe to file |
| Q3 | Should polling use exponential backoff? | V1: fixed interval. V2: optional backoff |
| Q4 | Should we support multiple simultaneous project_dirs on one client? | No — one client per project. Create multiple clients if needed |
