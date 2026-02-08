# AiderDesk CLI — User Guide

> **File:** `aider_cli.rb`
> **Depends on:** `lib/aider_desk_api.rb`
> **Dependencies:** Ruby stdlib only
> **Ruby version:** >= 2.7

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Configuration](#2-configuration)
   - [Environment Variables](#21-environment-variables)
   - [Config File (~/.aider_cli.yml)](#22-config-file-aider_cliyml)
   - [Precedence](#23-precedence)
3. [General Usage](#3-general-usage)
4. [Global Options](#4-global-options)
5. [Command Reference](#5-command-reference)
   - [Server & System](#51-server--system)
   - [Projects](#52-projects)
   - [Tasks](#53-tasks)
   - [Prompts](#54-prompts)
   - [Context Files](#55-context-files)
   - [Models](#56-models)
   - [Conversation Control](#57-conversation-control)
   - [Web Scraping](#58-web-scraping)
6. [Workflows & Recipes](#6-workflows--recipes)
7. [Scripting & Automation](#7-scripting--automation)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Quick Start

```bash
# Set credentials (one-time)
export AIDER_USERNAME=admin
export AIDER_PASSWORD=booberry
export AIDER_PROJECT_DIR=/path/to/your/project

# Check if server is alive
ruby aider_cli.rb health

# List all tasks
ruby aider_cli.rb task:list

# Create a task and run a prompt (one-shot)
ruby aider_cli.rb prompt:quick "Add a health check endpoint to the API"

# Run a prompt on a specific task
ruby aider_cli.rb prompt --task TASK_ID "Refactor the auth module"
```

---

## 2. Configuration

The CLI needs to know how to connect to your AiderDesk server. There are two ways to configure it.

### 2.1 Environment Variables

Set these in your shell profile (`~/.zshrc`, `~/.bashrc`, etc.) or export them per-session:

```bash
export AIDER_BASE_URL=http://localhost:24337    # Server URL (default if omitted)
export AIDER_USERNAME=admin                      # Basic Auth username
export AIDER_PASSWORD=booberry                   # Basic Auth password
export AIDER_PROJECT_DIR=/path/to/your/project   # Default project directory
```

### 2.2 Config File (`~/.aider_cli.yml`)

Create `~/.aider_cli.yml` for persistent configuration:

```yaml
base_url: http://localhost:24337
username: admin
password: booberry
project_dir: /Users/you/projects/my-project
default_model: ollama/llama3.1:8b
```

**Create it with one command:**

```bash
cat > ~/.aider_cli.yml << 'EOF'
base_url: http://localhost:24337
username: admin
password: booberry
project_dir: /Users/you/projects/my-project
EOF
```

### 2.3 Precedence

The CLI resolves configuration in this order (first match wins):

1. **ENV variables** (highest priority)
2. **`~/.aider_cli.yml`** file
3. **Built-in defaults** (`http://localhost:24337`, no auth)

This means ENV vars always override the YAML file, which is useful for one-off overrides:

```bash
# Use a different server just for this command:
AIDER_BASE_URL=http://other-host:9999 ruby aider_cli.rb health
```

---

## 3. General Usage

```
ruby aider_cli.rb [options] <command> [arguments...]
```

- **Options** can appear anywhere (before or after the command)
- **Command** is required (see §5 for the full list)
- **Arguments** are positional text passed to the command (used by `prompt` and `prompt:quick`)

### Available Commands

| Category | Commands |
|----------|----------|
| Server & System | `health`, `settings`, `os`, `versions` |
| Projects | `projects`, `project:open`, `project:close`, `project:settings`, `input-history` |
| Tasks | `task:create`, `task:list`, `task:load`, `task:delete`, `task:reset`, `task:duplicate`, `task:export` |
| Prompts | `prompt`, `prompt:quick` |
| Context Files | `context:list`, `context:add`, `context:drop` |
| Models | `model:set`, `model:architect`, `model:weak` |
| Conversation | `interrupt`, `clear-context`, `scrape` |

### Help

```bash
ruby aider_cli.rb --help
ruby aider_cli.rb -h
```

---

## 4. Global Options

These options can be used with any command. The CLI parses them regardless of position.

| Option | Type | Description |
|--------|------|-------------|
| `--task ID` | String | Task UUID |
| `--name NAME` | String | Task name (for `task:create`, `prompt:quick`) |
| `--mode MODE` | String | Prompt mode: `agent`, `code`, `ask`, `architect`, `context` |
| `--model MODEL` | String | Model identifier (e.g., `ollama/llama3.1:8b`) |
| `--path PATH` | String | File path (for context files, scraping) |
| `--url URL` | String | URL (for `scrape` command) |
| `--output FILE` | String | Output file path (for `task:export`) |
| `--timeout SECS` | Integer | Max wait time in seconds (for prompt commands) |
| `--interval SECS` | Integer | Poll interval in seconds (for prompt commands) |
| `--readonly` | Flag | Add context file as read-only |
| `--force` | Flag | Force refresh (for `versions`) |
| `-h`, `--help` | Flag | Show help text |

---

## 5. Command Reference

### 5.1 Server & System

#### `health`

Check if the AiderDesk server is reachable.

```bash
ruby aider_cli.rb health
# [OK] Server is alive

# Exit code: 0 on success, 1 on failure
```

Useful in scripts:

```bash
ruby aider_cli.rb health && echo "Ready" || echo "Server down"
```

#### `settings`

Display the full AiderDesk global settings.

```bash
ruby aider_cli.rb settings
# [OK] Settings
# {
#   "language": "en",
#   "theme": "dark",
#   "font": "Sono",
#   ...
# }
```

#### `os`

Get the server's operating system.

```bash
ruby aider_cli.rb os
# [OK] OS
# {
#   "os": "macos"
# }
```

#### `versions`

Check AiderDesk versions.

```bash
ruby aider_cli.rb versions

# Force a fresh check:
ruby aider_cli.rb versions --force
```

---

### 5.2 Projects

#### `projects`

List all open projects.

```bash
ruby aider_cli.rb projects
# [OK] Projects
# [
#   {
#     "baseDir": "/Users/you/projects/my-project",
#     "settings": { "mainModel": "ollama/llama3.1:8b", ... },
#     "active": true
#   }
# ]
```

#### `project:open`

Open the configured project in AiderDesk.

```bash
ruby aider_cli.rb project:open
# [OK] Project opened
```

#### `project:close`

Close/remove the configured project.

```bash
ruby aider_cli.rb project:close
# [OK] Project closed
```

#### `project:settings`

Get the current project's settings.

```bash
ruby aider_cli.rb project:settings
# [OK] Project settings
# { "mainModel": "ollama/llama3.1:8b", ... }
```

#### `input-history`

Get the prompt input history for the project.

```bash
ruby aider_cli.rb input-history
```

---

### 5.3 Tasks

#### `task:create`

Create a new task. Use `--name` to give it a descriptive name.

```bash
# Named task:
ruby aider_cli.rb task:create --name "Refactor Auth Module"
# [OK] Task created
# {
#   "id": "abc-123-...",
#   "name": "",
#   "mainModel": "ollama/llama3.1:8b",
#   ...
# }

# Quick unnamed task:
ruby aider_cli.rb task:create
```

**Save the task ID** — you'll need it for most other commands:

```bash
TASK_ID=$(ruby aider_cli.rb task:create --name "My Task" 2>/dev/null | ruby -rjson -e 'j=JSON.parse($stdin.read.lines[1..].join); puts j["id"]')
echo $TASK_ID
```

#### `task:list`

List all tasks for the project.

```bash
ruby aider_cli.rb task:list
# [OK] Tasks
# [
#   { "id": "abc-123", "name": "My Task", "mainModel": "ollama/llama3.1:8b", ... },
#   { "id": "def-456", "name": "Other Task", ... }
# ]
```

#### `task:load`

Load full task details including messages.

```bash
ruby aider_cli.rb task:load --task abc-123-def-456
```

#### `task:delete`

Delete a task permanently.

```bash
ruby aider_cli.rb task:delete --task abc-123-def-456
# [OK] Task deleted
```

#### `task:reset`

Clear all messages from a task, keeping the task itself.

```bash
ruby aider_cli.rb task:reset --task abc-123-def-456
# [OK] Task reset
```

#### `task:duplicate`

Create a copy of an existing task.

```bash
ruby aider_cli.rb task:duplicate --task abc-123-def-456
# [OK] Task duplicated
# { "id": "new-task-id-...", ... }
```

#### `task:export`

Export a task's conversation as markdown.

```bash
# Print to stdout:
ruby aider_cli.rb task:export --task abc-123-def-456

# Save to file:
ruby aider_cli.rb task:export --task abc-123-def-456 --output session.md
# [OK] Exported to session.md
```

---

### 5.4 Prompts

#### `prompt`

Run a prompt on an existing task. **Blocks until the agent finishes** (or timeout is reached), showing live progress.

**Required:** `--task`, prompt text as trailing arguments.

```bash
# Basic usage:
ruby aider_cli.rb prompt --task abc-123 "Fix the bug in the login controller"

# Specify mode:
ruby aider_cli.rb prompt --task abc-123 --mode code "Add input validation to User model"

# With custom timeout and poll interval:
ruby aider_cli.rb prompt --task abc-123 --timeout 300 --interval 3 "Refactor the entire auth system"
```

**Prompt modes:**

| Mode | Description |
|------|-------------|
| `agent` | Full autonomous agent (default) |
| `code` | Code editing mode |
| `ask` | Q&A mode (no file edits) |
| `architect` | High-level architectural planning |
| `context` | Context management mode |

**Live output example:**

```
[*] Running prompt on task abc-123 (mode: code)...
  [user] Fix the bug in the login controller
  [response-completed] I've identified and fixed the bug in `app/controllers/login_controller.rb`...
[OK] Prompt completed.
```

#### `prompt:quick`

**One-shot command:** Creates a new task, runs the prompt, and waits for completion. No `--task` needed.

```bash
# Simplest usage:
ruby aider_cli.rb prompt:quick "Add a README.md with project description"

# With a task name and mode:
ruby aider_cli.rb prompt:quick --name "Add README" --mode code "Create a comprehensive README.md"

# With custom timeout:
ruby aider_cli.rb prompt:quick --timeout 300 "Refactor the entire API layer"
```

**Output:**

```
[*] Creating task and running prompt (mode: agent)...
  [user] Add a README.md with project description
  [response-completed] I've created README.md with a comprehensive project description...
[OK] Done. Task ID: new-abc-123
```

---

### 5.5 Context Files

#### `context:list`

List all files in a task's context.

```bash
ruby aider_cli.rb context:list --task abc-123
# [OK] Context files
# [ { "path": "src/main.rb", "readOnly": false }, ... ]
```

#### `context:add`

Add a file to the task's context.

```bash
# Editable:
ruby aider_cli.rb context:add --task abc-123 --path src/models/user.rb

# Read-only:
ruby aider_cli.rb context:add --task abc-123 --path docs/schema.sql --readonly
```

#### `context:drop`

Remove a file from the task's context.

```bash
ruby aider_cli.rb context:drop --task abc-123 --path src/models/user.rb
```

---

### 5.6 Models

#### `model:set`

Set the main model for a task.

```bash
ruby aider_cli.rb model:set --task abc-123 --model ollama/llama3.1:8b
# [OK] Main model set
```

#### `model:architect`

Set the architect model.

```bash
ruby aider_cli.rb model:architect --task abc-123 --model anthropic/claude-3.5-sonnet
```

#### `model:weak`

Set the weak/fast model.

```bash
ruby aider_cli.rb model:weak --task abc-123 --model ollama/llama3.2:3b
```

---

### 5.7 Conversation Control

#### `interrupt`

Stop a currently running prompt.

```bash
ruby aider_cli.rb interrupt --task abc-123
# [OK] Interrupted
```

#### `clear-context`

Remove all files from a task's context.

```bash
ruby aider_cli.rb clear-context --task abc-123
# [OK] Context cleared
```

---

### 5.8 Web Scraping

#### `scrape`

Scrape a web page into the task's context.

```bash
# Scrape into context:
ruby aider_cli.rb scrape --task abc-123 --url https://docs.example.com/api

# Scrape and save to a file:
ruby aider_cli.rb scrape --task abc-123 --url https://docs.example.com/api --path docs/api-ref.md
```

---

## 6. Workflows & Recipes

### 6.1 Quick One-Shot Code Edit

The fastest way to make an AI-assisted change:

```bash
ruby aider_cli.rb prompt:quick --mode code "Add CORS middleware to the Express app"
```

### 6.2 Full Task Lifecycle

```bash
# 1. Create a task
ruby aider_cli.rb task:create --name "Auth Refactor"
# Note the task ID from output, e.g.: abc-123

# 2. Add context files
ruby aider_cli.rb context:add --task abc-123 --path src/auth.rb
ruby aider_cli.rb context:add --task abc-123 --path src/middleware.rb
ruby aider_cli.rb context:add --task abc-123 --path docs/auth-spec.md --readonly

# 3. Set the model
ruby aider_cli.rb model:set --task abc-123 --model ollama/llama3.1:8b

# 4. Run the first prompt
ruby aider_cli.rb prompt --task abc-123 --mode code "Extract auth logic into a separate concern"

# 5. Run a follow-up prompt (same task retains conversation history)
ruby aider_cli.rb prompt --task abc-123 --mode code "Now add tests for the new auth concern"

# 6. Export the full conversation
ruby aider_cli.rb task:export --task abc-123 --output auth-refactor-session.md

# 7. Clean up
ruby aider_cli.rb task:delete --task abc-123
```

### 6.3 Ask a Question Without Editing

Use `ask` mode when you want analysis or explanation without code changes:

```bash
ruby aider_cli.rb prompt:quick --mode ask "Explain the authentication flow in this codebase"
```

### 6.4 Architectural Planning

Use `architect` mode for high-level design:

```bash
ruby aider_cli.rb prompt:quick --mode architect \
  "Design a caching layer for the API. Consider Redis and in-memory options."
```

### 6.5 Scrape Documentation + Build Integration

```bash
# Create a task
ruby aider_cli.rb task:create --name "Stripe Integration"
# Task ID: abc-123

# Scrape the API docs
ruby aider_cli.rb scrape --task abc-123 --url https://stripe.com/docs/api --path docs/stripe-api.md

# Add as context
ruby aider_cli.rb context:add --task abc-123 --path docs/stripe-api.md --readonly

# Generate the integration
ruby aider_cli.rb prompt --task abc-123 --mode code \
  "Build a Stripe payment client based on the docs in context"
```

### 6.6 Interrupt a Runaway Task

If a prompt is taking too long or going in the wrong direction:

```bash
# In another terminal:
ruby aider_cli.rb interrupt --task abc-123
```

---

## 7. Scripting & Automation

### 7.1 Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error (connection failure, API error, missing required option) |

Use in scripts:

```bash
if ruby aider_cli.rb health; then
  echo "Server is up, proceeding..."
  ruby aider_cli.rb prompt:quick "Run lint and fix issues"
else
  echo "Server not available"
  exit 1
fi
```

### 7.2 Parse JSON Output

The CLI outputs JSON for data responses. Use `jq` or Ruby to parse:

```bash
# Get just the task IDs using jq:
ruby aider_cli.rb task:list 2>/dev/null | tail -n +2 | jq -r '.[].id'

# Get the active project's model:
ruby aider_cli.rb projects 2>/dev/null | tail -n +2 | jq -r '.[0].settings.mainModel'
```

> **Note:** The first line of successful output is `[OK] Label`. Data starts from line 2.

### 7.3 Shell Function Wrapper

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
aider() {
  ruby /path/to/aider_cli.rb "$@"
}
```

Then use:

```bash
aider health
aider task:list
aider prompt:quick "Add a Dockerfile"
```

### 7.4 Batch Processing

```bash
#!/bin/bash
TASKS=(
  "Add error handling to all API endpoints"
  "Add request logging middleware"
  "Add rate limiting to public endpoints"
)

for task in "${TASKS[@]}"; do
  echo "=== Running: $task ==="
  ruby aider_cli.rb prompt:quick --mode code --timeout 300 "$task"
  echo ""
done
```

### 7.5 CI/CD Integration

```yaml
# .github/workflows/ai-review.yml (example concept)
- name: AI Code Review
  env:
    AIDER_BASE_URL: ${{ secrets.AIDER_URL }}
    AIDER_USERNAME: ${{ secrets.AIDER_USER }}
    AIDER_PASSWORD: ${{ secrets.AIDER_PASS }}
    AIDER_PROJECT_DIR: ${{ github.workspace }}
  run: |
    ruby aider_cli.rb project:open
    ruby aider_cli.rb prompt:quick --mode ask \
      "Review the recent changes for bugs and security issues"
```

### 7.6 Create a Task, Capture the ID, and Use It

```bash
# Create and capture ID in one line:
TASK_ID=$(ruby aider_cli.rb task:create --name "Scripted Task" 2>/dev/null \
  | tail -n +2 | ruby -rjson -e 'puts JSON.parse(STDIN.read)["id"]')

echo "Working with task: $TASK_ID"

ruby aider_cli.rb context:add --task $TASK_ID --path src/main.rb
ruby aider_cli.rb prompt --task $TASK_ID --mode code "Add comprehensive error handling"
ruby aider_cli.rb task:export --task $TASK_ID --output session.md
ruby aider_cli.rb task:delete --task $TASK_ID
```

---

## 8. Troubleshooting

### "Server unreachable"

```
[ERROR] Server unreachable
```

**Causes:**
- AiderDesk is not running
- Wrong `base_url` (check port)
- Auth credentials not set

**Fix:**
```bash
# Verify server is running:
curl -s http://localhost:24337/api/settings

# Check your config:
echo $AIDER_BASE_URL
echo $AIDER_USERNAME
cat ~/.aider_cli.yml
```

### "--task is required for 'command'"

```
[ERROR] --task is required for 'prompt'
```

You forgot the `--task` option. Use `task:list` to find task IDs, or use `prompt:quick` which doesn't need one.

```bash
# Find your task ID:
ruby aider_cli.rb task:list

# Then use it:
ruby aider_cli.rb prompt --task YOUR_TASK_ID "your prompt"
```

### "No prompt text provided"

```
[ERROR] No prompt text provided
```

The prompt text goes after all options as trailing arguments:

```bash
# Wrong (no text):
ruby aider_cli.rb prompt --task abc-123

# Right:
ruby aider_cli.rb prompt --task abc-123 "Your prompt goes here"
```

### Prompt times out silently

If the agent is still working when timeout is reached, the CLI exits with `[OK]` but the agent continues in the background.

**Fix:** Increase the timeout:

```bash
ruby aider_cli.rb prompt --task abc-123 --timeout 600 "Complex refactoring task"
```

### JSON output is truncated

For large responses, pipe through `less` or redirect to a file:

```bash
ruby aider_cli.rb task:load --task abc-123 | less
ruby aider_cli.rb task:load --task abc-123 > task-data.json
```

### "Unknown command: xyz"

Check available commands:

```bash
ruby aider_cli.rb --help
```

Commands use colon separators for namespaces: `task:create`, `context:add`, `model:set`, etc.

### Config file not loading

The YAML config must be at exactly `~/.aider_cli.yml`. Verify:

```bash
cat ~/.aider_cli.yml
```

Keys must be strings matching exactly: `base_url`, `username`, `password`, `project_dir`.

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│  AiderDesk CLI — Quick Reference                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SETUP                                                          │
│    export AIDER_USERNAME=admin                                  │
│    export AIDER_PASSWORD=booberry                               │
│    export AIDER_PROJECT_DIR=/path/to/project                    │
│                                                                 │
│  BASICS                                                         │
│    aider health                  Check server                   │
│    aider projects                List projects                  │
│    aider task:list               List tasks                     │
│    aider task:create --name X    Create a task                  │
│                                                                 │
│  PROMPTS                                                        │
│    aider prompt:quick "..."      One-shot (creates task)        │
│    aider prompt --task ID "..."  Run on existing task           │
│    aider interrupt --task ID     Stop running prompt            │
│                                                                 │
│  CONTEXT                                                        │
│    aider context:add  --task ID --path file.rb                  │
│    aider context:drop --task ID --path file.rb                  │
│    aider context:list --task ID                                 │
│                                                                 │
│  MODELS                                                         │
│    aider model:set --task ID --model ollama/llama3.1:8b         │
│                                                                 │
│  MODES: agent | code | ask | architect | context                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
