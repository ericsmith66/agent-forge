require_relative '../lib/aider_desk/client'
require 'logger'
require 'date'

# Configuration
PROJECT_DIR = "/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild"
TIMESTAMP = Time.now.strftime("%Y%m%d_%H%M%S")
FILENAME = "hello_world_#{TIMESTAMP}.rb"
TASK_NAME = "Hello World Default Model: #{TIMESTAMP}"
MODE = "code" 

PROMPT = <<~PROMPT
  Create a ruby file named "#{FILENAME}" in the root directory.
  The file should contain a single ruby script that prints:
  "Hello Ruby World! The current time is #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
PROMPT

client = AiderDesk::Client.new(
  base_url: "http://localhost:24337",
  username: "admin",
  password: "booberry",
  project_dir: PROJECT_DIR,
  raise_on_error: true,
  read_timeout: 600,
  open_timeout: 60,
  preview_only: false 
)

puts "Creating task: #{TASK_NAME}..."
task_id = client.create_task_and_get_id(name: TASK_NAME, project_dir: PROJECT_DIR)
puts "Task created: #{task_id}"

puts "Running prompt in #{MODE} mode (Default Model)..."
start_time = Time.now
res = client.run_prompt_and_wait(
  task_id: task_id,
  prompt: PROMPT,
  mode: MODE,
  timeout: 600,
  project_dir: PROJECT_DIR
) do |msg|
  timestamp = Time.now.strftime("%H:%M:%S")
  role = msg["role"]
  type = msg["type"]
  puts "[#{timestamp}] #{role.to_s.upcase} (#{type}): #{msg["content"].to_s[0..100]}..."
end

end_time = Time.now
duration = end_time - start_time

puts "---"
puts "Task Status: #{client.task_status(task_id: task_id, project_dir: PROJECT_DIR).dig('state')}"
puts "Duration: #{duration.round(2)} seconds"

# Verify file exists
file_path = File.join(PROJECT_DIR, FILENAME)
if File.exist?(file_path)
  puts "SUCCESS: File #{FILENAME} created!"
  puts "Content:"
  puts File.read(file_path)
else
  puts "FAILURE: File #{FILENAME} not found in #{PROJECT_DIR}"
end
