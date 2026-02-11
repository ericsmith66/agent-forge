require_relative '../lib/aider_desk/client'
require 'logger'
require 'time'

# Evaluation Configuration 3: Focused + Ollama (Qwen2.5-Coder:32B)
PROJECT_DIR = "/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild"
TASK_NAME = "Config 3: Focused + Ollama (Qwen2.5)"
MODE = "code" # Focused mode
MODEL = "ollama/qwen2.5-coder:32b"

PROMPT = <<~PROMPT
# Task: Implement Prefab HTTP Client Service (AiderDesk Evaluation)

Implement the `PrefabClient` service class to query Prefab's REST API at `http://localhost:8080` (configurable).  
Follow the exact style, structure, error handling, logging, and testing expectations from PRD 1.2.

### Service Class: `PrefabClient`
Location: `app/services/prefab_client.rb`

#### Required Methods
1. `homes`  
   - GET `/homes`  
   - Returns: Array of home objects or `[]` on failure

2. `rooms(home)`  
   - GET `/rooms/:home`  
   - `home` = name or uuid  
   - Returns: Array of room objects or `[]` on failure

3. `accessories(home, room)`  
   - GET `/accessories/:home/:room`  
   - Returns: Array of accessory objects or `[]` on failure

4. `scenes(home)`  
   - GET `/scenes/:home`  
   - Returns: Array of scene objects or `[]` on failure

(Optional – implement if time allows)  
5. `accessory_details(home, room, accessory)`  
   - GET `/accessories/:home/:room/:accessory`  
   - Returns: Single accessory object or `nil` on failure

#### Configuration
- Base URL: `http://localhost:8080` (default)  
- Override: `ENV['PREFAB_API_URL']`  
- Timeout: 5 seconds

#### HTTP Client
- Use `HTTParty`

#### Error Handling & Logging
- Rescue connection errors, timeouts, non-200 responses, etc.  
- Log failure via `Rails.logger.error("PrefabClient error: \#{e.message}")`
- Return `[]` for array-returning methods, `nil` for detail method  
- Define custom error class: `class ConnectionError < StandardError; end`

#### URL Encoding
- Properly URL-encode all path parameters (home/room names may contain spaces, special characters)

### Testing Requirements
Location: `spec/services/prefab_client_spec.rb`

Use **WebMock** for stubbing.

Required test coverage:
- Success case for each method  
- Failure cases: connection refused, timeout, 500 status, non-JSON body  
- URL encoding of special characters (e.g. "Mom's House", "Living Room #2")  
- ENV var override (custom `PREFAB_API_URL`)  
- Timeout configuration (5 seconds)  
- Logging on error  

### Success Criteria for this task
- All required methods implemented  
- Correct return values on success/failure  
- URL encoding handled correctly  
- ENV configuration respected  
- Errors logged appropriately  
- Custom `ConnectionError` class defined  
- RSpec tests pass  
- RuboCop clean (or minimal justified offenses)

You are allowed to create any needed spec files, but focus on `spec/services/prefab_client_spec.rb`.  
Use Rails 8+ idioms.  
Do not add any unnecessary dependencies.  
After you finish, I will run `rspec` and review the code.

Begin implementation now.
PROMPT

client = AiderDesk::Client.new(
  base_url: "http://localhost:24337",
  username: "admin",
  password: "booberry",
  project_dir: PROJECT_DIR,
  raise_on_error: true,
  read_timeout: 900 # 15 minutes for 32B model
)

puts "[#{Time.now.iso8601}] Creating task: #{TASK_NAME}..."
task_id = client.create_task_and_get_id(name: TASK_NAME, project_dir: PROJECT_DIR)
puts "[#{Time.now.iso8601}] Task created: #{task_id}"

puts "[#{Time.now.iso8601}] Setting models to #{MODEL}..."
client.set_main_model(task_id: task_id, main_model: MODEL, project_dir: PROJECT_DIR)
client.set_architect_model(task_id: task_id, architect_model: MODEL, project_dir: PROJECT_DIR)

puts "[#{Time.now.iso8601}] Enabling auto-approve..."
client.update_task(task_id: task_id, updates: { "autoApprove" => true }, project_dir: PROJECT_DIR)

puts "[#{Time.now.iso8601}] Running prompt in #{MODE} mode..."
start_time = Time.now

begin
  client.run_prompt(task_id: task_id, prompt: PROMPT, mode: MODE, project_dir: PROJECT_DIR)
rescue Net::ReadTimeout
  puts "[#{Time.now.iso8601}] Prompt call timed out (Expected for 32B model). Polling for progress..."
end

last_msg_count = 0
loop do
  status_resp = client.task_status(task_id: task_id, project_dir: PROJECT_DIR)
  state = status_resp&.dig("state")
  
  messages = client.task_messages(task_id: task_id, project_dir: PROJECT_DIR)
  if messages.size > last_msg_count
    messages[last_msg_count..-1].each do |m|
      role = m["role"] || m["type"]
      content = m["content"]
      puts "[#{Time.now.strftime("%H:%M:%S")}] #{role.upcase}: #{content.to_s[0..150]}..."
    end
    last_msg_count = messages.size
  end

  puts "[#{Time.now.strftime("%H:%M:%S")}] Current state: #{state}"
  
  if state == "completed"
    puts "SUCCESS: Task completed!"
    break
  elsif state == "error"
    puts "FAILURE: Task failed with error."
    break
  elsif state == "idle" && last_msg_count > 1
    # Check if a file was actually created to see if it's "done" but state didn't update
    if File.exist?("#{PROJECT_DIR}/app/services/prefab_client.rb")
       puts "SUCCESS: PrefabClient found! (Even though state is idle)"
       break
    end
    puts "WARNING: Task is IDLE. Check UI for manual confirmation."
  end

  if Time.now - start_time > 1800 # 30 minute limit
    puts "FAILURE: Evaluation timed out after 30 minutes."
    break
  end

  sleep 20
end

duration = Time.now - start_time
puts "---"
puts "Duration: #{duration.round(2)} seconds"
