# frozen_string_literal: true

require_relative '../lib/aider_desk/client'
require 'logger'

# Evaluation: Hello World v2 targeting eureka-homekit-rebuild
PROJECT_DIR = "/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild"
MODEL = "ollama/qwen2.5-coder:32b"
timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
FILENAME = "hello_world_qwen_#{timestamp}.py"
TASK_NAME = "Hello World Build v2 (Qwen Ruby)"

client = AiderDesk::Client.new(
  base_url: "http://localhost:24337",
  username: "admin",
  password: "booberry",
  project_dir: PROJECT_DIR,
  raise_on_error: true,
  read_timeout: 600
)

puts "[*] Starting AiderDesk Hello World v2 (Ruby Client)..."
puts "[*] Targeting model: #{MODEL}"
puts "[*] Project directory: #{PROJECT_DIR}"

# 1. Health check
begin
  health = client.health
  if health[:ok]
    puts "[*] Health check successful: Server is alive."
  else
    puts "[!] Health check failed: #{health[:error]}"
    exit 1
  end
rescue => e
  puts "[!] Failed to connect to server: #{e.message}"
  exit 1
end

# 2. Ensure project is 'open'
puts "[*] Ensuring project is open..."
client.add_open_project(project_dir: PROJECT_DIR)

# 3. Create a new task
puts "[*] Creating a new task..."
task_id = client.create_task_and_get_id(name: TASK_NAME, project_dir: PROJECT_DIR)
if task_id.nil?
  puts "[!] Failed to create task."
  exit 1
end
puts "[*] Task created. ID: #{task_id}"

# 4. Configure task models using specific endpoints
puts "[*] Setting main model to #{MODEL}..."
client.set_main_model(task_id: task_id, main_model: MODEL, project_dir: PROJECT_DIR)

puts "[*] Setting architect model to #{MODEL}..."
client.set_architect_model(task_id: task_id, architect_model: MODEL, project_dir: PROJECT_DIR)

# Set autoApprove
puts "[*] Enabling auto-approve..."
client.update_task(task_id: task_id, updates: { "autoApprove" => true }, project_dir: PROJECT_DIR)

# 4b. Verify settings stuck
puts "[*] Verifying task settings..."
task_data = client.task_status(task_id: task_id, project_dir: PROJECT_DIR)
if task_data
  reported_model = task_data["mainModel"]
  puts "[*] Reported Task Main Model: #{reported_model}"
  if reported_model != MODEL
    puts "[!] WARNING: Model mismatch! Expected #{MODEL}, got #{reported_model}"
  end
else
  puts "[!] Could not verify settings."
end

# 5. Run the prompt
sleep 2
prompt = "Create a python script named #{FILENAME} that prints 'Hello from Qwen Ruby' and the current date and time. Use the datetime module."
puts "[*] Running prompt: #{prompt}"

begin
  # run_prompt is synchronous in AiderDesk and waits for completion
  client.run_prompt(task_id: task_id, prompt: prompt, mode: "code", project_dir: PROJECT_DIR)
  puts "[*] Prompt call returned."
rescue => e
  puts "[!] Prompt call errored or timed out: #{e.message}"
end

# 6. Polling loop for verification
puts "[*] Monitoring task progress (polling for completion)..."
start_time = Time.now
timeout = 600 # 10 minutes
last_msg_count = 0
target_file = File.join(PROJECT_DIR, FILENAME)

while Time.now - start_time < timeout
  begin
    task_data = client.load_task(task_id: task_id, project_dir: PROJECT_DIR).data
    if task_data
      messages = task_data["messages"] || []
      if messages.size > last_msg_count
        messages[last_msg_count..-1].each do |m|
          role = m["type"] || m["role"] || "unknown"
          content = m["content"] || ""
          display = content.length > 80 ? content[0...80] + ".." : content
          puts "[#{role}]: #{display}"
          
          if m["type"] == "response-completed"
            puts "[*] Agent signaled completion."
          end
        end
        last_msg_count = messages.size
      end
    end

    if File.exist?(target_file)
      puts "[*] SUCCESS: #{target_file} has been created!"
      puts "[*] File content:"
      puts File.read(target_file)
      break
    end
  rescue => e
    puts "[!] Polling error: #{e.message}"
  end

  sleep 10
  if (Time.now - start_time).to_i % 60 == 0
    puts "[*] Still working... (#{(Time.now - start_time).to_i}s elapsed)"
  end
end

puts "[*] DONE."
