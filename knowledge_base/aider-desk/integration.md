# AiderDesk Integration Guide

**Last updated:** 2026-02-08  
**Epic:** Epic-001 — AiderDesk Bootstrap  
**PRDs:** PRD-001.1 through PRD-001.5

---

## Overview

agent-forge integrates with [AiderDesk](https://aiderdesk.com) via a Ruby client library (`lib/aider_desk/client.rb`) and a SmartProxy adapter (`lib/smart_proxy/aider_desk_adapter.rb`). The adapter is registered as an `ai-agents` tool, allowing the Coordinator to hand off coding tasks to the Coder role.

**Architecture:**
```
Coordinator → Coder (ai-agents handoff) → AiderDeskAdapter → AiderDesk::Client → REST API
```

---

## Prerequisites

- AiderDesk desktop app installed and running on `http://localhost:24337`
- Ruby 3.3+
- Test project bootstrapped at `projects/aider-desk-test/`

See [setup.md](setup.md) for installation details.

---

## Ruby Client Usage

### Basic initialization

```ruby
require 'aider_desk/client'

client = AiderDesk::Client.new(
  base_url: 'http://localhost:24337',   # default
  preview_only: true,                    # default — no auto-apply
  project_dir: 'projects/aider-desk-test'
)
```

### Health check

```ruby
result = client.health
# => { ok: true, status: 200, data: { "mainModel" => "claude-sonnet-4-20250514", ... } }

client.health_check
# => true / false
```

### Create a task and run a prompt

```ruby
# One-shot: create task + run prompt + poll for completion
result = client.run_and_wait(
  prompt: "Add a status column to TestEvent model",
  name: "my-task",
  mode: "code",          # or "agent", "ask", "architect"
  timeout: 120,
  poll_interval: 5
) do |msg|
  puts "[#{msg['type']}] #{msg['content']&.slice(0, 80)}"
end

result[:task_id]   # => "abc-123"
result[:messages]   # => array of message hashes
result[:response]   # => AiderDesk::Response
```

### Step-by-step task management

```ruby
# Create task
task_id = client.create_task_and_get_id(name: "my-task")

# Run prompt with polling
response = client.run_prompt_and_wait(
  task_id: task_id,
  prompt: "Create hello.rb with a greeting method",
  mode: "code",
  timeout: 120
) { |msg| puts msg['content'] }

# Check task status
status = client.task_status(task_id: task_id)

# Get messages
messages = client.task_messages(task_id: task_id)

# Cleanup
client.delete_task(task_id: task_id)
```

### Context file management

```ruby
client.add_context_file(task_id: task_id, path: "app/models/user.rb", read_only: true)
client.get_context_files(task_id: task_id)
client.drop_context_file(task_id: task_id, path: "app/models/user.rb")
```

### Error handling

```ruby
# With raise_on_error: false (default) — returns Response with error
response = client.get_settings
unless response.success?
  puts "Error: #{response.error}"
end

# With raise_on_error: true — raises exceptions
client = AiderDesk::Client.new(raise_on_error: true)
begin
  client.get_settings
rescue AiderDesk::ConnectionError => e
  puts "AiderDesk not running: #{e.message}"
rescue AiderDesk::AuthError => e
  puts "Auth failed: #{e.message}"
rescue AiderDesk::ApiError => e
  puts "API error: #{e.message}"
end
```

---

## SmartProxy Adapter Usage

The adapter wraps the client with safety validation and `ai-agents` tool integration.

```ruby
require 'smart_proxy/aider_desk_adapter'

adapter = SmartProxy::AiderDeskAdapter.new(
  polling_timeout: 120,
  shared_context: "You are a Ruby on Rails expert."
)

result = adapter.run_prompt(
  nil,                                    # task_id (nil = create new)
  "Add a status column to TestEvent",     # prompt
  "code",                                 # mode
  "projects/aider-desk-test"              # project_dir (must be under projects/)
)

result[:status]    # => :ok, :error, or :timeout
result[:task_id]   # => "abc-123"
result[:diffs]     # => array of diff/edit messages
result[:messages]  # => all collected messages
```

### Safety features

- **preview_only enforced** — adapter rejects clients with `preview_only: false`
- **project_dir validation** — rejects paths outside `projects/` (prevents traversal attacks)
- **shared context injection** — prepends ai-agents context to all prompts

### Tool schema (for ai-agents registration)

```ruby
SmartProxy::AiderDeskAdapter.tool_schema
# => { name: "aider_desk", description: "...", parameters: { prompt: ..., mode: ..., project_dir: ... } }
```

---

## CLI Usage

The CLI is at `bin/aider_cli`. It wraps the Ruby client for terminal use.

```bash
# Health check
bin/aider_cli health

# With custom URL
bin/aider_cli health --url http://localhost:24337

# Create a task
bin/aider_cli task:create --project /path/to/project --name "my-task"

# List tasks
bin/aider_cli task:list --project /path/to/project

# Quick prompt (creates task + runs + polls)
bin/aider_cli prompt:quick "Add a hello method to app/models/user.rb" \
  --project /path/to/project --mode code --timeout 120

# Run prompt on existing task
bin/aider_cli prompt "Fix the failing test" --task abc-123 --project /path/to/project

# Get task status / messages
bin/aider_cli task:status --task abc-123 --project /path/to/project
bin/aider_cli task:messages --task abc-123 --project /path/to/project

# View settings
bin/aider_cli settings
```

---

## curl Examples

### Health check / settings
```bash
curl -s http://localhost:24337/api/settings | jq .
```

### Create a task
```bash
curl -s -X POST http://localhost:24337/api/project/tasks/new \
  -H "Content-Type: application/json" \
  -d '{"projectDir":"/path/to/project","name":"curl-test"}' | jq .
```

### Run a prompt
```bash
curl -s -X POST http://localhost:24337/api/run-prompt \
  -H "Content-Type: application/json" \
  -d '{
    "projectDir": "/path/to/project",
    "taskId": "TASK_ID",
    "prompt": "Create a hello.rb file",
    "mode": "code"
  }' | jq .
```

### Load task (check status/messages)
```bash
curl -s -X POST http://localhost:24337/api/project/tasks/load \
  -H "Content-Type: application/json" \
  -d '{"projectDir":"/path/to/project","id":"TASK_ID"}' | jq .
```

### List tasks
```bash
curl -s "http://localhost:24337/api/project/tasks?projectDir=/path/to/project" | jq .
```

### Delete a task
```bash
curl -s -X POST http://localhost:24337/api/project/tasks/delete \
  -H "Content-Type: application/json" \
  -d '{"projectDir":"/path/to/project","id":"TASK_ID"}' | jq .
```

---

## Troubleshooting

### AiderDesk not running
```
[ERROR] AiderDesk unreachable: Connection refused
```
**Fix:** Start the AiderDesk desktop application. Verify it's listening:
```bash
curl -s http://localhost:24337/api/settings
```

### Authentication errors (401)
```
AiderDesk API error 401: ...
```
**Fix:** Check credentials in Rails encrypted credentials:
```bash
bin/rails credentials:edit
```
Add:
```yaml
aider_desk:
  username: your_username
  password: your_password
```

### project_dir validation error
```
project_dir must be under projects/
```
**Fix:** Ensure the path is relative to the agent-forge root and starts with `projects/`. Absolute paths must resolve to within the `projects/` directory.

### Polling timeout
```
status: :timeout
```
**Fix:** Increase timeout (default 120s):
```ruby
adapter = SmartProxy::AiderDeskAdapter.new(polling_timeout: 300)
```
Or via CLI: `--timeout 300`

### VCR cassette errors in tests
```
VCR::Errors::UnhandledHTTPRequestError
```
**Fix:** Re-record cassettes with a live AiderDesk instance:
```bash
# Delete old cassettes
rm test/fixtures/vcr_cassettes/aider_desk/*.yml

# Run integration tests with recording enabled
SKIP_INTEGRATION=0 ruby -Ilib:test test/integration/aider_desk/client_integration_test.rb
```

### SimpleCov below 90%
Check the coverage report:
```bash
open coverage/index.html
```
Add tests for uncovered methods in `lib/aider_desk/` and `lib/smart_proxy/`.

---

## Related Documents

- [AiderDesk API Reference](aider_api.md)
- [AiderDesk Setup Guide](setup.md)
- [Epic-001 Overview](../epics/epic-1-bootstrap/0000-overview-epic-001-aider-bootstrap-comments-V2.md)
- [PRD-001.1: Local Setup](../epics/epic-1-bootstrap/PRD-1-01-local-setup-verification.md)
- [PRD-001.2: Ruby Client & CLI](../epics/epic-1-bootstrap/PRD-1-02-ruby-client-cli.md)
- [PRD-001.3: SmartProxy Adapter](../epics/epic-1-bootstrap/PRD-1-03-smartproxy-adapter.md)
- [PRD-001.4: Test Project Bootstrap](../epics/epic-1-bootstrap/PRD-1-04-test-project-bootstrap.md)
- [PRD-001.5: E2E Tests & Docs](../epics/epic-1-bootstrap/PRD-1-05-e2e-tests-docs.md)
