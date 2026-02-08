#!/usr/bin/env ruby
require_relative 'lib/aider_desk_api'
require 'yaml'
require 'optparse'
require 'json'

# ─── Configuration ──────────────────────────────────────────────────────────

CONFIG_FILE = File.expand_path("~/.aider_cli.yml")

def load_config
  defaults = {
    "base_url"    => "http://localhost:24337",
    "username"    => nil,
    "password"    => nil,
    "project_dir" => nil,
    "default_model" => nil
  }

  if File.exist?(CONFIG_FILE)
    yaml = YAML.safe_load(File.read(CONFIG_FILE)) || {}
    defaults.merge(yaml)
  else
    defaults
  end
end

def build_client(config)
  AiderDesk::Client.new(
    base_url:    config["base_url"],
    username:    config["username"],
    password:    config["password"],
    project_dir: config["project_dir"]
  )
end

# ─── Output Helpers ─────────────────────────────────────────────────────────

def puts_json(data)
  puts JSON.pretty_generate(data)
rescue
  puts data.inspect
end

def puts_response(res, label = nil)
  if res.success?
    puts "[OK] #{label}" if label
    puts_json(res.data) if res.data
    puts res.body if res.data.nil? && res.body && !res.body.empty?
  else
    $stderr.puts "[ERROR] #{label}: #{res.error || res.status} #{res.body}"
    exit 1
  end
end

# ─── Commands ───────────────────────────────────────────────────────────────

def cmd_health(client, _args, _opts)
  if client.health_check
    puts "[OK] Server is alive"
  else
    $stderr.puts "[ERROR] Server unreachable"
    exit 1
  end
end

def cmd_settings(client, _args, _opts)
  puts_response client.get_settings, "Settings"
end

def cmd_projects(client, _args, _opts)
  puts_response client.get_projects, "Projects"
end

def cmd_versions(client, _args, opts)
  puts_response client.get_versions(force_refresh: opts[:force]), "Versions"
end

def cmd_os(client, _args, _opts)
  puts_response client.get_os, "OS"
end

def cmd_task_create(client, _args, opts)
  puts_response client.create_task(name: opts[:name]), "Task created"
end

def cmd_task_list(client, _args, _opts)
  puts_response client.list_tasks, "Tasks"
end

def cmd_task_load(client, _args, opts)
  require_opt!(opts, :task, "task:load")
  puts_response client.load_task(task_id: opts[:task]), "Task"
end

def cmd_task_delete(client, _args, opts)
  require_opt!(opts, :task, "task:delete")
  puts_response client.delete_task(task_id: opts[:task]), "Task deleted"
end

def cmd_task_reset(client, _args, opts)
  require_opt!(opts, :task, "task:reset")
  puts_response client.reset_task(task_id: opts[:task]), "Task reset"
end

def cmd_task_duplicate(client, _args, opts)
  require_opt!(opts, :task, "task:duplicate")
  puts_response client.duplicate_task(task_id: opts[:task]), "Task duplicated"
end

def cmd_task_export(client, _args, opts)
  require_opt!(opts, :task, "task:export")
  res = client.export_task_markdown(task_id: opts[:task])
  if res.success?
    if opts[:output]
      File.write(opts[:output], res.body)
      puts "[OK] Exported to #{opts[:output]}"
    else
      puts res.body
    end
  else
    $stderr.puts "[ERROR] Export failed: #{res.error || res.status}"
    exit 1
  end
end

def cmd_prompt(client, args, opts)
  require_opt!(opts, :task, "prompt")
  prompt_text = args.join(" ")
  if prompt_text.empty?
    $stderr.puts "[ERROR] No prompt text provided"
    exit 1
  end

  mode = opts[:mode] || "agent"
  puts "[*] Running prompt on task #{opts[:task]} (mode: #{mode})..."

  final = client.run_prompt_and_wait(
    task_id: opts[:task],
    prompt: prompt_text,
    mode: mode,
    timeout: opts[:timeout] || 120,
    poll_interval: opts[:interval] || 5
  ) do |msg|
    role = msg["type"] || msg["role"] || "unknown"
    content = msg.fetch("content", "")
    display = content.length > 120 ? "#{content[0...120]}..." : content
    puts "  [#{role}] #{display}"
  end

  if final.success?
    puts "[OK] Prompt completed."
  else
    $stderr.puts "[ERROR] #{final.error || final.status}"
    exit 1
  end
end

def cmd_prompt_quick(client, args, opts)
  prompt_text = args.join(" ")
  if prompt_text.empty?
    $stderr.puts "[ERROR] No prompt text provided"
    exit 1
  end

  mode = opts[:mode] || "agent"
  name = opts[:name] || "CLI Quick Task"
  puts "[*] Creating task and running prompt (mode: #{mode})..."

  result = client.create_task_and_run(
    prompt: prompt_text,
    name: name,
    mode: mode,
    timeout: opts[:timeout] || 120,
    poll_interval: opts[:interval] || 5
  ) do |msg|
    role = msg["type"] || msg["role"] || "unknown"
    content = msg.fetch("content", "")
    display = content.length > 120 ? "#{content[0...120]}..." : content
    puts "  [#{role}] #{display}"
  end

  if result[:response]&.success?
    puts "[OK] Done. Task ID: #{result[:task_id]}"
  else
    $stderr.puts "[ERROR] Failed. Task ID: #{result[:task_id]}"
    exit 1
  end
end

def cmd_context_list(client, _args, opts)
  require_opt!(opts, :task, "context:list")
  puts_response client.get_context_files(task_id: opts[:task]), "Context files"
end

def cmd_context_add(client, _args, opts)
  require_opt!(opts, :task, "context:add")
  require_opt!(opts, :path, "context:add")
  puts_response client.add_context_file(task_id: opts[:task], path: opts[:path], read_only: opts[:readonly] || false), "File added"
end

def cmd_context_drop(client, _args, opts)
  require_opt!(opts, :task, "context:drop")
  require_opt!(opts, :path, "context:drop")
  puts_response client.drop_context_file(task_id: opts[:task], path: opts[:path]), "File dropped"
end

def cmd_model_set(client, _args, opts)
  require_opt!(opts, :task, "model:set")
  require_opt!(opts, :model, "model:set")
  puts_response client.set_main_model(task_id: opts[:task], main_model: opts[:model]), "Main model set"
end

def cmd_model_architect(client, _args, opts)
  require_opt!(opts, :task, "model:architect")
  require_opt!(opts, :model, "model:architect")
  puts_response client.set_architect_model(task_id: opts[:task], architect_model: opts[:model]), "Architect model set"
end

def cmd_model_weak(client, _args, opts)
  require_opt!(opts, :task, "model:weak")
  require_opt!(opts, :model, "model:weak")
  puts_response client.set_weak_model(task_id: opts[:task], weak_model: opts[:model]), "Weak model set"
end

def cmd_interrupt(client, _args, opts)
  require_opt!(opts, :task, "interrupt")
  puts_response client.interrupt(task_id: opts[:task]), "Interrupted"
end

def cmd_clear_context(client, _args, opts)
  require_opt!(opts, :task, "clear-context")
  puts_response client.clear_context(task_id: opts[:task]), "Context cleared"
end

def cmd_scrape(client, _args, opts)
  require_opt!(opts, :task, "scrape")
  require_opt!(opts, :url, "scrape")
  puts_response client.scrape_web(task_id: opts[:task], url: opts[:url], file_path: opts[:path]), "Scrape"
end

def cmd_project_open(client, _args, _opts)
  puts_response client.add_open_project, "Project opened"
end

def cmd_project_close(client, _args, _opts)
  puts_response client.remove_open_project, "Project closed"
end

def cmd_project_settings(client, _args, _opts)
  puts_response client.get_project_settings, "Project settings"
end

def cmd_input_history(client, _args, _opts)
  puts_response client.get_input_history, "Input history"
end

# ─── Helpers ────────────────────────────────────────────────────────────────

def require_opt!(opts, key, cmd_name)
  return if opts[key]
  $stderr.puts "[ERROR] --#{key} is required for '#{cmd_name}'"
  exit 1
end

# ─── Command Registry ──────────────────────────────────────────────────────

COMMANDS = {
  "health"            => method(:cmd_health),
  "settings"          => method(:cmd_settings),
  "projects"          => method(:cmd_projects),
  "versions"          => method(:cmd_versions),
  "os"                => method(:cmd_os),
  "task:create"       => method(:cmd_task_create),
  "task:list"         => method(:cmd_task_list),
  "task:load"         => method(:cmd_task_load),
  "task:delete"       => method(:cmd_task_delete),
  "task:reset"        => method(:cmd_task_reset),
  "task:duplicate"    => method(:cmd_task_duplicate),
  "task:export"       => method(:cmd_task_export),
  "prompt"            => method(:cmd_prompt),
  "prompt:quick"      => method(:cmd_prompt_quick),
  "context:list"      => method(:cmd_context_list),
  "context:add"       => method(:cmd_context_add),
  "context:drop"      => method(:cmd_context_drop),
  "model:set"         => method(:cmd_model_set),
  "model:architect"   => method(:cmd_model_architect),
  "model:weak"        => method(:cmd_model_weak),
  "interrupt"         => method(:cmd_interrupt),
  "clear-context"     => method(:cmd_clear_context),
  "scrape"            => method(:cmd_scrape),
  "project:open"      => method(:cmd_project_open),
  "project:close"     => method(:cmd_project_close),
  "project:settings"  => method(:cmd_project_settings),
  "input-history"     => method(:cmd_input_history),
}.freeze

# ─── Main ───────────────────────────────────────────────────────────────────

opts = {}

global_parser = OptionParser.new do |o|
  o.banner = "Usage: ruby aider_cli.rb [options] <command> [args...]"
  o.separator ""
  o.separator "Commands: #{COMMANDS.keys.join(', ')}"
  o.separator ""
  o.separator "Options:"

  o.on("--task ID",       "Task ID")                          { |v| opts[:task] = v }
  o.on("--name NAME",     "Task name")                        { |v| opts[:name] = v }
  o.on("--mode MODE",     "Prompt mode (agent/code/ask/architect/context)") { |v| opts[:mode] = v }
  o.on("--model MODEL",   "Model identifier")                 { |v| opts[:model] = v }
  o.on("--path PATH",     "File path")                        { |v| opts[:path] = v }
  o.on("--url URL",       "URL for scraping")                 { |v| opts[:url] = v }
  o.on("--output FILE",   "Output file path")                 { |v| opts[:output] = v }
  o.on("--timeout SECS",  Integer, "Timeout in seconds")      { |v| opts[:timeout] = v }
  o.on("--interval SECS", Integer, "Poll interval in seconds"){ |v| opts[:interval] = v }
  o.on("--readonly",      "Add file as read-only")            { opts[:readonly] = true }
  o.on("--force",         "Force refresh")                    { opts[:force] = true }
  o.on("-h", "--help",    "Show this help")                   { puts o; exit }
end

global_parser.parse!

command = ARGV.shift

unless command && COMMANDS[command]
  if command
    $stderr.puts "Unknown command: #{command}"
  else
    $stderr.puts "No command specified."
  end
  $stderr.puts global_parser
  exit 1
end

remaining_args = ARGV.dup
ARGV.clear

config = load_config
client = build_client(config)
COMMANDS[command].call(client, remaining_args, opts)
