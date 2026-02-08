#!/usr/bin/env ruby
require_relative 'lib/aider_desk_api'

# Configuration
PROJECT_DIR = "/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild"
MODEL = "ollama/llama3.1:8b"

def log(msg)
  puts "[*] #{msg}"
end

def error(msg)
  puts "[!] #{msg}"
  exit 1
end

def test_api
  model = MODEL

  # Check for model argument
  if ARGV.length > 1 && ARGV[0] == "--model"
    model = ARGV[1]
  end

  # Ensure model starts with ollama/ if it doesn't already
  if model.include?(":") && !model.start_with?("ollama/")
    model = "ollama/#{model}"
  end

  client = AiderDesk::Client.new(
    base_url:    "http://localhost:24337",
    username:    "admin",
    password:    "booberry",
    project_dir: PROJECT_DIR
  )

  log "Starting AiderDesk API test on #{client.base_url}..."

  # 1. Health check
  if client.health_check
    log "Health check successful: Server is alive."
  else
    error "Health check failed: Server unreachable."
  end

  # 2. Ensure project is 'open'
  log "Ensuring project is open: #{PROJECT_DIR}"
  client.add_open_project

  # 3. Create a new task
  log "Creating a new task..."
  res = client.create_task(name: "API Proof of Life Task (Ollama)")
  error "Failed to create task: #{res.status} - #{res.body}" unless res.success?

  task_id = res.data["id"]
  error "Task created but no ID returned: #{res.data}" unless task_id
  log "Successfully created task. ID: #{task_id}"

  # 4. Force model settings
  log "Configuring task models to #{model}..."

  provider = "ollama"
  model_name = model
  if model.include?("/")
    provider, model_name = model.split("/", 2)
  end

  res = client.update_task(task_id: task_id, updates: {
    "mainModel"      => model,
    "architectModel" => model,
    "model"          => model_name,
    "provider"       => provider,
    "autoApprove"    => true
  })

  if res.success?
    log "Task models updated successfully."
  else
    error "Failed to update task models: #{res.status} - #{res.body}"
  end

  # 4b. Verify settings
  log "Verifying task settings..."
  res = client.load_task(task_id: task_id)
  if res.success?
    task_data = res.data.fetch("task", {})
    reported_model    = task_data["mainModel"]
    reported_provider = task_data["provider"]
    log "Reported Task Model: #{reported_model} (Provider: #{reported_provider})"
    log "WARNING: Model mismatch! Expected #{model}, got #{reported_model}" if reported_model != model
  end

  # 5. Run a prompt and wait for completion
  log "Running prompt on task #{task_id} using #{model} (code mode)..."
  prompt_text = "Write the word 'SUCCESS' to a file named PROOF<YY-MM-DD-HH-MM-SS>.txt. give me back the exact path where you wrote the file"

  final = client.run_prompt_and_wait(
    task_id: task_id,
    prompt: prompt_text,
    mode: "code",
    timeout: 120,
    poll_interval: 5
  ) do |msg|
    role = msg["type"] || msg["role"] || "unknown"
    content = msg.fetch("content", "")
    display = content.length > 100 ? "#{content[0...100]}.." : content
    log "New Message [#{role}]: #{display}"
  end

  if final.success?
    log "DONE. Check the AiderDesk GUI for final verification."
  else
    error "Failed to run prompt: #{final.status} - #{final.body}"
  end
end

test_api if __FILE__ == $PROGRAM_NAME
