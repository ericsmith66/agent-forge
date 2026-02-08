# AiderDesk Ruby API Library — User Guide

> **File:** `lib/aider_desk_api.rb`
> **Dependencies:** Ruby stdlib only (`net/http`, `json`, `uri`, `logger`)
> **Ruby version:** >= 2.7

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Installation & Setup](#2-installation--setup)
3. [Client Configuration](#3-client-configuration)
4. [The Response Object](#4-the-response-object)
5. [Error Handling](#5-error-handling)
6. [API Reference](#6-api-reference)
   - [System](#61-system)
   - [Settings](#62-settings)
   - [Prompts](#63-prompts)
   - [Context Files](#64-context-files)
   - [Custom Commands](#65-custom-commands)
   - [Projects](#66-projects)
   - [Tasks](#67-tasks)
   - [Messages](#68-messages)
   - [Conversation](#69-conversation)
   - [Model Settings](#610-model-settings)
   - [Worktrees](#611-worktrees)
7. [Convenience Methods](#7-convenience-methods)
8. [Real-World Use Cases](#8-real-world-use-cases)
9. [Logging & Debugging](#9-logging--debugging)
10. [Tips & Best Practices](#10-tips--best-practices)

---

## 1. Quick Start

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  base_url:    "http://localhost:24337",
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/your/project"
)

# Health check
puts client.health_check  # => true

# Create a task and run a prompt in one call
result = client.create_task_and_run(
  prompt: "Add a README.md with project description",
  name:   "Add README",
  mode:   "code"
) do |msg|
  puts "#{msg['type']}: #{msg['content']}"
end

puts "Task ID: #{result[:task_id]}"
```

That's it — 10 lines to go from zero to a working AI coding session.

---

## 2. Installation & Setup

No gem installation needed. The library is a single file using only Ruby stdlib.

**Require it in your script:**

```ruby
# If your script is in the project root:
require_relative 'lib/aider_desk_api'

# If your script is elsewhere, use the full path:
require '/path/to/project/lib/aider_desk_api'
```

**Prerequisites:**
- AiderDesk must be running (default: `http://localhost:24337`)
- If Basic Auth is enabled, you need the username and password

---

## 3. Client Configuration

### 3.1 Constructor Options

```ruby
client = AiderDesk::Client.new(
  base_url:        "http://localhost:24337",  # AiderDesk server URL
  username:        "admin",                    # Basic Auth username (nil = no auth)
  password:        "booberry",                 # Basic Auth password
  project_dir:     "/path/to/project",         # Default project directory
  logger:          Logger.new($stdout),        # Custom logger instance
  raise_on_error:  false,                      # Raise ApiError on non-2xx responses
  read_timeout:    300,                        # HTTP read timeout in seconds
  open_timeout:    30                          # HTTP connection timeout in seconds
)
```

All parameters are optional and have sensible defaults.

### 3.2 Environment Variables

Every configuration option can be set via environment variables. They serve as fallbacks when no explicit value is passed to the constructor:

| ENV Variable | Maps To | Default |
|-------------|---------|---------|
| `AIDER_BASE_URL` | `base_url` | `http://localhost:24337` |
| `AIDER_USERNAME` | `username` | `nil` (no auth) |
| `AIDER_PASSWORD` | `password` | `nil` |
| `AIDER_PROJECT_DIR` | `project_dir` | `nil` |

```ruby
# With ENV vars set, you can use a minimal constructor:
# export AIDER_BASE_URL=http://localhost:24337
# export AIDER_USERNAME=admin
# export AIDER_PASSWORD=booberry
# export AIDER_PROJECT_DIR=/path/to/project

client = AiderDesk::Client.new  # picks up everything from ENV
```

### 3.3 Configuration Precedence

Explicit argument → ENV variable → built-in default

```ruby
# Explicit wins over ENV:
client = AiderDesk::Client.new(base_url: "http://other-host:9999")
# Uses http://other-host:9999 even if AIDER_BASE_URL is set
```

### 3.4 project_dir Behavior

Most methods require a `project_dir`. You can:

1. **Set it once at init** (recommended):
   ```ruby
   client = AiderDesk::Client.new(project_dir: "/my/project")
   client.create_task(name: "My Task")  # uses /my/project automatically
   ```

2. **Override per-call:**
   ```ruby
   client.create_task(name: "Task", project_dir: "/other/project")
   ```

3. **Omit both** → raises `ArgumentError` with a clear message

---

## 4. The Response Object

Every API method returns an `AiderDesk::Response`:

```ruby
response = client.get_settings

response.success?  # => true (status 200-299, no connection error)
response.status    # => 200 (HTTP status code, 0 if connection failed)
response.data      # => {"language"=>"en", "theme"=>"dark", ...} (parsed JSON)
response.body      # => '{"language":"en",...}' (raw response body string)
response.error     # => nil (or error message string on failure)
response.to_s      # => "Response(200)" or "Response(500, error=...)"
```

### Key behaviors:

- `data` returns `nil` if the body is empty or not valid JSON
- `data` is lazily parsed and cached — safe to call multiple times
- On connection failure, `status` is `0` and `error` contains the exception message
- Non-JSON responses (like markdown export) are available via `body`

---

## 5. Error Handling

### 5.1 Default Mode (no exceptions)

By default, API errors do **not** raise exceptions. Check `success?`:

```ruby
res = client.create_task(name: "Test")

if res.success?
  task_id = res.data["id"]
  puts "Created task: #{task_id}"
else
  puts "Failed (#{res.status}): #{res.error || res.body}"
end
```

### 5.2 Exception Mode

Pass `raise_on_error: true` to raise `AiderDesk::ApiError` on any non-2xx response or connection failure:

```ruby
client = AiderDesk::Client.new(raise_on_error: true)

begin
  res = client.create_task(name: "Test")
  puts res.data["id"]
rescue AiderDesk::ApiError => e
  puts "API error: #{e.message}"
  puts "Status: #{e.response.status}"
  puts "Body: #{e.response.body}"
end
```

### 5.3 Connection Failures

If the server is unreachable, you get a Response with `status: 0`:

```ruby
res = client.get_settings
unless res.success?
  if res.status == 0
    puts "Cannot connect: #{res.error}"
  else
    puts "Server error: #{res.status}"
  end
end
```

---

## 6. API Reference

### 6.1 System

#### `get_env_var(key:, base_dir: nil)`

Retrieve an environment variable from the server.

```ruby
res = client.get_env_var(key: "OPENAI_API_KEY")
puts res.data  # => {"value" => "sk-..."}

# With a base directory for .env file resolution:
res = client.get_env_var(key: "MY_VAR", base_dir: "/path/to/dir")
```

---

### 6.2 Settings

#### `get_settings`

Get the current AiderDesk global settings.

```ruby
res = client.get_settings
puts res.data["theme"]     # => "dark"
puts res.data["language"]  # => "en"
```

#### `update_settings(settings)`

Update global settings. Pass a hash with the settings to change.

```ruby
client.update_settings({ "server" => { "enabled" => true } })
```

#### `get_recent_projects`

```ruby
res = client.get_recent_projects
res.data.each { |p| puts p["projectDir"] }
```

#### `add_recent_project(project_dir:)` / `remove_recent_project(project_dir:)`

```ruby
client.add_recent_project(project_dir: "/new/project")
client.remove_recent_project(project_dir: "/old/project")
```

#### `set_zoom(level:)`

Set the UI zoom level (0.5 to 3.0).

```ruby
client.set_zoom(level: 1.2)
```

#### `get_versions(force_refresh: false)`

```ruby
res = client.get_versions
puts res.data

# Force a fresh check:
res = client.get_versions(force_refresh: true)
```

#### `download_latest`

Trigger download of the latest AiderDesk version.

```ruby
client.download_latest
```

#### `get_release_notes` / `clear_release_notes`

```ruby
notes = client.get_release_notes
puts notes.data

client.clear_release_notes
```

#### `get_os`

```ruby
res = client.get_os
puts res.data["os"]  # => "macos"
```

---

### 6.3 Prompts

#### `run_prompt(task_id:, prompt:, mode: "agent")`

Send a prompt to a task. This is **asynchronous** — the server accepts the request and processes it in the background.

**Modes:** `agent`, `code`, `ask`, `architect`, `context`

```ruby
res = client.run_prompt(
  task_id: "abc-123",
  prompt:  "Refactor the User model to use concerns",
  mode:    "code"
)

if res.success?
  puts "Prompt accepted"
  # Poll load_task to monitor progress (or use run_prompt_and_wait)
end
```

#### `save_prompt(task_id:, prompt:)`

Save a prompt for later without executing it.

```ruby
client.save_prompt(task_id: "abc-123", prompt: "TODO: refactor auth module")
```

---

### 6.4 Context Files

#### `add_context_file(task_id:, path:, read_only: false)`

Add a file to the task's context window.

```ruby
# Editable file:
client.add_context_file(task_id: "abc-123", path: "src/models/user.rb")

# Read-only reference:
client.add_context_file(task_id: "abc-123", path: "docs/schema.sql", read_only: true)
```

#### `drop_context_file(task_id:, path:)`

Remove a file from context.

```ruby
client.drop_context_file(task_id: "abc-123", path: "src/models/user.rb")
```

#### `get_context_files(task_id:)`

List all files currently in the task's context.

```ruby
res = client.get_context_files(task_id: "abc-123")
res.data.each do |file|
  status = file["readOnly"] ? "(read-only)" : "(editable)"
  puts "#{file['path']} #{status}"
end
```

#### `get_addable_files(task_id:, search_regex: nil)`

Get files that can be added to context, optionally filtered by regex.

```ruby
# All addable files:
res = client.get_addable_files(task_id: "abc-123")

# Only Ruby files:
res = client.get_addable_files(task_id: "abc-123", search_regex: '.*\.rb$')
```

#### `get_all_files(task_id:, use_git: false)`

Get all project files.

```ruby
res = client.get_all_files(task_id: "abc-123", use_git: true)
```

---

### 6.5 Custom Commands

#### `get_custom_commands(project_dir:)`

```ruby
res = client.get_custom_commands
res.data.each { |cmd| puts cmd }
```

#### `run_custom_command(task_id:, command_name:, args: [], mode: "agent")`

```ruby
client.run_custom_command(
  task_id:      "abc-123",
  command_name: "lint",
  args:         ["--fix"],
  mode:         "code"
)
```

---

### 6.6 Projects

#### `get_projects`

List all open projects.

```ruby
res = client.get_projects
res.data.each do |proj|
  active = proj["active"] ? " (active)" : ""
  puts "#{proj['baseDir']}#{active} — model: #{proj.dig('settings', 'mainModel')}"
end
```

#### `add_open_project(project_dir:)` / `remove_open_project(project_dir:)`

Open or close a project in AiderDesk.

```ruby
client.add_open_project
client.add_open_project(project_dir: "/other/project")

client.remove_open_project
```

#### `set_active_project(project_dir:)`

```ruby
client.set_active_project
```

#### `start_project(project_dir:)` / `stop_project(project_dir:)` / `restart_project(project_dir:)`

```ruby
client.start_project
client.stop_project
client.restart_project
```

#### `get_project_settings(project_dir:)` / `update_project_settings(project_dir:, **settings)`

```ruby
res = client.get_project_settings
puts res.data

client.update_project_settings("mainModel" => "ollama/llama3.1:8b")
```

#### `update_project_order(project_dirs:)`

Reorder open projects in the UI.

```ruby
client.update_project_order(project_dirs: ["/project-a", "/project-b"])
```

#### `get_input_history(project_dir:)`

```ruby
res = client.get_input_history
res.data.each { |entry| puts entry }
```

#### `validate_path(path:)` / `is_project_path(path:)`

```ruby
res = client.validate_path(path: "src/main.rb")
puts res.data

res = client.is_project_path(path: "/absolute/path/to/check")
puts res.data
```

#### `file_suggestions(current_path:, directories_only: false)`

Get file/directory autocomplete suggestions.

```ruby
res = client.file_suggestions(current_path: "src/")
res.data.each { |s| puts s }

res = client.file_suggestions(current_path: "src/", directories_only: true)
```

#### `paste_image(task_id:, base64_image_data: nil)`

Paste an image into the task context.

```ruby
require 'base64'
image_data = Base64.strict_encode64(File.read("screenshot.png"))
client.paste_image(task_id: "abc-123", base64_image_data: image_data)
```

#### `apply_edits(task_id:, edits:)`

Apply file edits programmatically.

```ruby
client.apply_edits(task_id: "abc-123", edits: [
  {
    "path"     => "src/config.rb",
    "original" => "timeout = 30",
    "updated"  => "timeout = 60"
  }
])
```

#### `run_command(task_id:, command:)`

Execute a shell command in the project context.

```ruby
res = client.run_command(task_id: "abc-123", command: "bundle exec rspec")
puts res.data
```

#### `init_rules(task_id:)`

Initialize project rules/conventions.

```ruby
client.init_rules(task_id: "abc-123")
```

#### `scrape_web(task_id:, url:, file_path: nil)`

Scrape a web page and optionally save to a file.

```ruby
# Scrape into context:
client.scrape_web(task_id: "abc-123", url: "https://docs.example.com/api")

# Scrape and save to file:
client.scrape_web(
  task_id:   "abc-123",
  url:       "https://docs.example.com/api",
  file_path: "docs/external/api-reference.md"
)
```

---

### 6.7 Tasks

#### `create_task(name: nil, parent_id: nil)`

Create a new task (conversation thread).

```ruby
res = client.create_task(name: "Refactor Authentication")
task_id = res.data["id"]
puts "Created: #{task_id}"

# Create a subtask:
res = client.create_task(name: "Sub-task", parent_id: task_id)
```

#### `update_task(task_id:, updates:)`

Update task properties.

```ruby
client.update_task(task_id: "abc-123", updates: {
  "name"        => "Renamed Task",
  "mainModel"   => "ollama/llama3.1:8b",
  "autoApprove" => true
})
```

#### `load_task(task_id:)`

Load full task data including messages.

```ruby
res = client.load_task(task_id: "abc-123")
task = res.data

puts "Name: #{task.dig('task', 'name')}"
puts "Messages: #{task.fetch('messages', []).length}"

task.fetch("messages", []).each do |msg|
  puts "[#{msg['type']}] #{msg['content']&.slice(0, 80)}"
end
```

#### `list_tasks(project_dir:)`

List all tasks for a project.

```ruby
res = client.list_tasks
res.data.each do |task|
  puts "#{task['id']} — #{task['name']} (model: #{task['mainModel']})"
end
```

#### `delete_task(task_id:)`

```ruby
client.delete_task(task_id: "abc-123")
```

#### `duplicate_task(task_id:)`

Create a copy of an existing task.

```ruby
res = client.duplicate_task(task_id: "abc-123")
new_id = res.data["id"]
```

#### `fork_task(task_id:, message_id:)`

Fork a task from a specific message point.

```ruby
client.fork_task(task_id: "abc-123", message_id: "msg-456")
```

#### `reset_task(task_id:)`

Clear all messages and state from a task.

```ruby
client.reset_task(task_id: "abc-123")
```

#### `export_task_markdown(task_id:)`

Export the full conversation as markdown.

```ruby
res = client.export_task_markdown(task_id: "abc-123")
File.write("session-export.md", res.body)
```

#### `resume_task(task_id:)`

Resume a paused task.

```ruby
client.resume_task(task_id: "abc-123")
```

---

### 6.8 Messages

#### `remove_last_message(task_id:)`

```ruby
client.remove_last_message(task_id: "abc-123")
```

#### `remove_message(task_id:, message_id:)`

Remove a specific message.

```ruby
client.remove_message(task_id: "abc-123", message_id: "msg-456")
```

#### `remove_messages_up_to(task_id:, message_id:)`

Remove all messages up to (and including) a specific message.

```ruby
client.remove_messages_up_to(task_id: "abc-123", message_id: "msg-456")
```

---

### 6.9 Conversation

#### `redo_prompt(task_id:, mode:, updated_prompt: nil)`

Re-execute the last prompt, optionally with changes.

```ruby
# Redo exactly as-is in a different mode:
client.redo_prompt(task_id: "abc-123", mode: "architect")

# Redo with a modified prompt:
client.redo_prompt(
  task_id:        "abc-123",
  mode:           "code",
  updated_prompt: "Same task but also add tests"
)
```

#### `compact_conversation(task_id:, mode:, custom_instructions: nil)`

Compact/summarize the conversation to reduce token usage.

```ruby
client.compact_conversation(task_id: "abc-123", mode: "agent")

client.compact_conversation(
  task_id:             "abc-123",
  mode:                "agent",
  custom_instructions: "Focus on the auth refactoring decisions"
)
```

#### `handoff_conversation(task_id:, focus: nil)`

Generate a conversation handoff summary.

```ruby
client.handoff_conversation(task_id: "abc-123")

client.handoff_conversation(
  task_id: "abc-123",
  focus:   "Summarize what was done and list remaining TODO items"
)
```

#### `interrupt(task_id:)`

Stop a currently running prompt.

```ruby
client.interrupt(task_id: "abc-123")
```

#### `clear_context(task_id:)`

Remove all files from the task's context.

```ruby
client.clear_context(task_id: "abc-123")
```

#### `answer_question(task_id:, answer:)`

Respond to a question the agent is waiting on.

```ruby
client.answer_question(task_id: "abc-123", answer: "Yes, proceed with the migration.")
```

---

### 6.10 Model Settings

#### `set_main_model(task_id:, main_model:)`

```ruby
client.set_main_model(task_id: "abc-123", main_model: "ollama/llama3.1:8b")
```

#### `set_weak_model(task_id:, weak_model:)`

```ruby
client.set_weak_model(task_id: "abc-123", weak_model: "ollama/llama3.2:3b")
```

#### `set_architect_model(task_id:, architect_model:)`

```ruby
client.set_architect_model(task_id: "abc-123", architect_model: "anthropic/claude-3.5-sonnet")
```

#### `set_edit_formats(edit_formats:)`

```ruby
client.set_edit_formats(edit_formats: {
  "typescript" => "diff",
  "ruby"       => "whole"
})
```

---

### 6.11 Worktrees

#### `worktree_merge_to_main(task_id:, squash: true, target_branch: nil, commit_message: nil)`

```ruby
client.worktree_merge_to_main(
  task_id:        "abc-123",
  squash:         true,
  target_branch:  "main",
  commit_message: "feat: add user authentication"
)
```

#### `worktree_apply_uncommitted(task_id:, target_branch: nil)`

```ruby
client.worktree_apply_uncommitted(task_id: "abc-123", target_branch: "develop")
```

#### `worktree_revert_last_merge(task_id:)`

```ruby
client.worktree_revert_last_merge(task_id: "abc-123")
```

#### `worktree_branches(project_dir:)`

```ruby
res = client.worktree_branches
res.data.each { |branch| puts branch }
```

#### `worktree_status(task_id:, target_branch: nil)`

```ruby
res = client.worktree_status(task_id: "abc-123", target_branch: "main")
puts res.data
```

#### `worktree_rebase_from_branch(task_id:, from_branch: nil)`

```ruby
client.worktree_rebase_from_branch(task_id: "abc-123", from_branch: "main")
```

#### `worktree_abort_rebase(task_id:)` / `worktree_continue_rebase(task_id:)`

```ruby
client.worktree_abort_rebase(task_id: "abc-123")
client.worktree_continue_rebase(task_id: "abc-123")
```

#### `worktree_resolve_conflicts(task_id:)`

Let the AI agent resolve merge conflicts.

```ruby
client.worktree_resolve_conflicts(task_id: "abc-123")
```

---

## 7. Convenience Methods

These combine multiple API calls for common workflows.

### `health_check`

Returns `true` if the server is reachable and responding, `false` otherwise.

```ruby
if client.health_check
  puts "Server is up"
else
  puts "Server is down"
  exit 1
end
```

### `run_prompt_and_wait(task_id:, prompt:, mode:, timeout:, poll_interval:, &block)`

Sends a prompt, then polls `load_task` until a `response-completed` message is detected or the timeout is reached. Yields each new message to the optional block.

```ruby
response = client.run_prompt_and_wait(
  task_id:       "abc-123",
  prompt:        "Add input validation to the User model",
  mode:          "code",
  timeout:       180,     # seconds (default: 120)
  poll_interval: 3        # seconds between polls (default: 5)
) do |msg|
  role    = msg["type"] || msg["role"]
  content = msg.fetch("content", "")
  puts "[#{role}] #{content[0..100]}"
end

if response.success?
  puts "Prompt completed successfully"
else
  puts "Prompt failed or timed out"
end
```

**Return value:** The final `AiderDesk::Response` from `load_task`.

### `create_task_and_run(prompt:, name:, mode:, timeout:, poll_interval:, &block)`

One-shot: creates a new task, runs a prompt on it, and waits for completion.

```ruby
result = client.create_task_and_run(
  prompt:  "Create a Rake task for database seeding",
  name:    "DB Seed Task",
  mode:    "code",
  timeout: 120
) do |msg|
  puts "  [#{msg['type']}] #{msg['content']&.slice(0, 80)}"
end

puts "Task ID: #{result[:task_id]}"
puts "Messages: #{result[:messages].length}"
puts "Success: #{result[:response]&.success?}"
```

**Return value:** A hash with keys `:task_id`, `:response`, `:messages`.

---

## 8. Real-World Use Cases

### 8.1 Automated Code Review Script

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/project"
)

# Get the changed files from git
changed_files = `git diff --name-only HEAD~1`.strip.split("\n")

# Create a review task
res = client.create_task(name: "Automated Code Review")
task_id = res.data["id"]

# Add changed files to context as read-only
changed_files.each do |file|
  client.add_context_file(task_id: task_id, path: file, read_only: true)
end

# Run the review
client.run_prompt_and_wait(
  task_id: task_id,
  prompt:  "Review the files in context for bugs, security issues, and code style. Provide a summary.",
  mode:    "ask"
) do |msg|
  if msg["type"] == "response-completed"
    puts msg["content"]
  end
end
```

### 8.2 Batch Task Runner

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/project"
)

tasks = [
  { name: "Add logging",     prompt: "Add structured logging to all controller actions", mode: "code" },
  { name: "Add validations", prompt: "Add input validation to all model attributes",     mode: "code" },
  { name: "Add tests",       prompt: "Write RSpec tests for the User model",             mode: "code" },
]

tasks.each do |t|
  puts "=== #{t[:name]} ==="
  result = client.create_task_and_run(
    name:    t[:name],
    prompt:  t[:prompt],
    mode:    t[:mode],
    timeout: 300
  )
  puts "  Task #{result[:task_id]}: #{result[:response]&.success? ? 'OK' : 'FAILED'}"
  puts ""
end
```

### 8.3 Interactive Agent Session

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/project"
)

res = client.create_task(name: "Interactive Session")
task_id = res.data["id"]

# Add files to context
client.add_context_file(task_id: task_id, path: "src/app.rb")
client.add_context_file(task_id: task_id, path: "src/routes.rb")

loop do
  print "\nprompt> "
  input = $stdin.gets&.strip
  break if input.nil? || input == "exit"

  client.run_prompt_and_wait(
    task_id: task_id,
    prompt:  input,
    mode:    "code",
    timeout: 120
  ) do |msg|
    if msg["type"] == "response-completed"
      puts "\n#{msg['content']}"
    end
  end
end

puts "Session ended. Task ID: #{task_id}"
```

### 8.4 Model Comparison

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/project"
)

models = ["ollama/llama3.1:8b", "ollama/codellama:13b"]
prompt = "Write a binary search function in Ruby"

models.each do |model|
  res = client.create_task(name: "Test: #{model}")
  task_id = res.data["id"]

  client.set_main_model(task_id: task_id, main_model: model)

  start = Time.now
  result = client.run_prompt_and_wait(
    task_id: task_id,
    prompt:  prompt,
    mode:    "code",
    timeout: 180
  )
  elapsed = Time.now - start

  puts "#{model}: #{elapsed.round(1)}s, success=#{result.success?}"
end
```

### 8.5 Web Scraping + Context Injection

```ruby
require_relative 'lib/aider_desk_api'

client = AiderDesk::Client.new(
  username:    "admin",
  password:    "booberry",
  project_dir: "/path/to/project"
)

res = client.create_task(name: "API Integration")
task_id = res.data["id"]

# Scrape API docs into the project
client.scrape_web(
  task_id:   task_id,
  url:       "https://api.example.com/docs",
  file_path: "docs/external-api.md"
)

# Add the scraped docs as read-only context
client.add_context_file(task_id: task_id, path: "docs/external-api.md", read_only: true)

# Now ask the agent to build an integration
client.run_prompt_and_wait(
  task_id: task_id,
  prompt:  "Build a Ruby client for the API documented in docs/external-api.md",
  mode:    "code"
)
```

---

## 9. Logging & Debugging

### 9.1 Default Logger

By default, the client logs at `WARN` level to `$stdout`. You'll only see connection errors.

### 9.2 Enable Debug Logging

To see every HTTP request and response:

```ruby
logger = Logger.new($stdout)
logger.level = Logger::DEBUG

client = AiderDesk::Client.new(
  username: "admin",
  password: "booberry",
  logger:   logger
)

client.get_settings
# D, [...] DEBUG -- : GET http://localhost:24337/api/settings
# D, [...] DEBUG -- : Response 200: {"language":"en","theme":"dark",...}
```

### 9.3 Log to File

```ruby
logger = Logger.new("aider_api.log", "daily")
logger.level = Logger::DEBUG

client = AiderDesk::Client.new(logger: logger)
```

### 9.4 Custom Logger Format

```ruby
logger = Logger.new($stdout)
logger.formatter = proc { |severity, time, _, msg| "[#{severity}] #{msg}\n" }
logger.level = Logger::DEBUG

client = AiderDesk::Client.new(logger: logger)
```

---

## 10. Tips & Best Practices

### Set project_dir once
Don't repeat it on every call. Set it at client initialization.

### Use `create_task_and_run` for one-off operations
It handles task creation, prompt execution, and polling in a single call.

### Use blocks for progress monitoring
Both `run_prompt_and_wait` and `create_task_and_run` accept blocks for real-time message output.

### Increase timeout for complex prompts
The default 120s timeout may not be enough for large codebases or complex tasks. Set `timeout: 300` or higher.

### Use `read_only: true` for reference files
When adding context files that shouldn't be modified, mark them read-only.

### Clean up tasks
Delete tasks you no longer need to keep the UI clean:
```ruby
client.delete_task(task_id: old_task_id)
```

### Use ENV vars in CI/CD
Set `AIDER_BASE_URL`, `AIDER_USERNAME`, `AIDER_PASSWORD`, and `AIDER_PROJECT_DIR` as environment variables for automation scripts.

### Check `success?` before accessing `data`
Always check the response status before reading parsed data to avoid nil errors:
```ruby
res = client.load_task(task_id: id)
if res.success?
  messages = res.data.fetch("messages", [])
end
```
