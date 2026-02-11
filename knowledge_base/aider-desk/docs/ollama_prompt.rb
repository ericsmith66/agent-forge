#!/usr/bin/env ruby
# frozen_string_literal: true

=begin
General-purpose AiderDesk + Ollama prompt runner (Ruby).

Ruby port of knowledge_base/ollama_prompt.py with two transport modes:
  --transport socketio  (default) Engine.IO HTTP long-polling for real-time events
  --transport rest      REST polling via /api/project/tasks/load (fallback)

Features:
- Ollama health check + warm-up (keeps model loaded)
- Structured failure classification
- Stale-chunk detection and per-phase timing
- Log tailing with Ollama error pattern detection
- CLI options: prompt, model, retries, timeout, mode, edit format, transport, etc.

Limitations / Ruby-specific notes:
- Socket.IO is implemented via Engine.IO HTTP long-polling (pure stdlib).
  This gives real-time event parity with the Python version without any gems.
- REST transport polls /api/project/tasks/load and may miss some events.
- Uses only Ruby stdlib (Net::HTTP, JSON, OptionParser, Thread, etc.).

Usage:
  ruby knowledge_base/ollama_prompt.rb --prompt "Create hello.rb that prints hello world"
  ruby knowledge_base/ollama_prompt.rb --transport rest --timeout 180
  ruby knowledge_base/ollama_prompt.rb --debug --edit-format whole --mode agent
=end

require 'net/http'
require 'json'
require 'uri'
require 'optparse'
require 'base64'

$debug = false

OLLAMA_ERROR_PATTERNS = %w[error out\ of\ memory cuda failed\ to\ load context\ length\ exceeded connection\ refused].freeze
STALE_CHUNK_TIMEOUT = 30

def ts
  Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L')
end

def log(level, msg)
  return if level == 'DEBUG' && !$debug
  puts "#{ts} [#{level}] #{msg}"
end

module FailureReason
  COLD_START = 'cold_start'
  PARTIAL_RESPONSE = 'partial'
  QUESTION_UNANSWERED = 'question'
  CONNECTION_ERROR = 'connection'
  OLLAMA_ERROR = 'ollama_error'
  UNKNOWN = 'unknown'
end

def classify_failure(monitor_snap, prompt_result, elapsed)
  if monitor_snap[:chunks_received].zero?
    return elapsed > 60 ? FailureReason::COLD_START : FailureReason::CONNECTION_ERROR
  end
  return FailureReason::QUESTION_UNANSWERED if monitor_snap[:question_pending]
  if prompt_result[:error]
    err = prompt_result[:error].downcase
    return FailureReason::CONNECTION_ERROR if err.include?('timeout') || err.include?('connection')
    return FailureReason::OLLAMA_ERROR
  end
  return FailureReason::PARTIAL_RESPONSE if monitor_snap[:chunks_received] > 0
  FailureReason::UNKNOWN
end

# ── HTTP helpers ─────────────────────────────────────────────────────────────

def http_request(method, url, timeout: 30, username: nil, password: nil, payload: nil)
  uri = URI(url)
  req = case method
        when :get  then Net::HTTP::Get.new(uri)
        when :post then Net::HTTP::Post.new(uri)
        else raise ArgumentError, "Unsupported: #{method}"
        end
  req.basic_auth(username, password) if username
  if payload
    req['Content-Type'] = 'application/json'
    req.body = JSON.generate(payload)
  end
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.read_timeout = timeout
  http.open_timeout = [timeout, 30].min
  response = http.request(req)
  [response.code.to_i, response.body]
rescue StandardError => e
  [0, e.message]
end

def api_get(api_url, path, username:, password:, timeout: 30)
  url = "#{api_url}#{path}"
  log('DEBUG', "GET  #{url}")
  status, body = http_request(:get, url, timeout: timeout, username: username, password: password)
  log('DEBUG', "  -> #{status} (#{body.to_s.bytesize}B)")
  [status, body]
end

def api_post(api_url, path, payload, username:, password:, timeout: 30)
  url = "#{api_url}#{path}"
  log('DEBUG', "POST #{url}  body=#{(payload ? JSON.generate(payload) : 'null')[0, 200]}")
  status, body = http_request(:post, url, timeout: timeout, username: username, password: password, payload: payload)
  log('DEBUG', "  -> #{status} (#{body.to_s.bytesize}B)")
  [status, body]
end

def parse_json(body)
  return nil if body.nil? || body.strip.empty?
  JSON.parse(body)
rescue JSON::ParserError
  nil
end

# ── Ollama helpers ───────────────────────────────────────────────────────────

def check_ollama_health(model, ollama_url)
  status, body = http_request(:get, "#{ollama_url}/api/tags", timeout: 5)
  return false unless status == 200
  models = (parse_json(body) || {}).fetch('models', []).map { |m| m['name'] }
  short = model.sub(%r{\Aollama/}, '')
  if models.any? { |n| n.include?(short) }
    log('PASS', "Ollama healthy, model #{short} available")
    true
  else
    log('FAIL', "Model #{short} not found. Available: #{models}")
    false
  end
rescue StandardError => e
  log('FAIL', "Cannot reach Ollama: #{e}")
  false
end

def check_ollama_running_models(ollama_url)
  status, body = http_request(:get, "#{ollama_url}/api/ps", timeout: 5)
  return [] unless status == 200
  models = (parse_json(body) || {}).fetch('models', [])
  models.each { |m| log('OLLAMA', "  Loaded: #{m['name']} (size=#{m['size'] || '?'})") }
  models
rescue StandardError
  []
end

def warm_up_ollama(model, timeout:, ollama_url:)
  short = model.sub(%r{\Aollama/}, '')
  log('INFO', "Warming up Ollama model: #{short} (may take several minutes)...")
  status, body = http_request(:post, "#{ollama_url}/api/generate", timeout: timeout,
                              payload: { model: short, prompt: 'hi', stream: false, keep_alive: '24h' })
  if status == 200
    log('PASS', "Model #{short} is warm and ready")
    true
  else
    log('WARN', "Warm-up returned #{status}: #{body.to_s[0, 200]}")
    false
  end
rescue StandardError => e
  log('WARN', "Warm-up failed: #{e}")
  false
end

# ── Log tailer ───────────────────────────────────────────────────────────────

def start_log_tailer(log_path, label)
  stop = { stop: false }
  Thread.new do
    unless File.exist?(log_path)
      log('WARN', "#{label} log not found at #{log_path} — tailing disabled")
      Thread.exit
    end
    File.open(log_path, 'r') do |f|
      f.seek(0, IO::SEEK_END)
      until stop[:stop]
        line = f.gets
        if line
          line = line.strip
          next if line.empty?
          if label == 'OLLAMA' && OLLAMA_ERROR_PATTERNS.any? { |p| line.downcase.include?(p) }
            log('OLLAMA-ERR', "⚠️  #{line}")
          else
            log(label, line)
          end
        else
          sleep 0.5
        end
      end
    end
  rescue StandardError => e
    log('WARN', "#{label} log tailer error: #{e}")
  end
  stop
end

# ── Background prompt sender ────────────────────────────────────────────────

def fire_prompt_async(api_url, username, password, project_dir, task_id, prompt, mode)
  result = { status: nil, error: nil, done: false }
  Thread.new do
    begin
      status, _body = api_post(api_url, '/run-prompt',
                               { projectDir: project_dir, taskId: task_id, prompt: prompt, mode: mode },
                               username: username, password: password, timeout: 300)
      result[:status] = status
    rescue StandardError => e
      result[:error] = e.message
    ensure
      result[:done] = true
    end
  end
  log('INFO', 'run-prompt fired in background thread')
  result
end

# ── Socket.IO Monitor (Engine.IO HTTP long-polling, pure stdlib) ─────────────

class SocketIOMonitor
  def initialize(base_url:, project_dir:, username:, password:)
    @base_url = base_url
    @project_dir = project_dir
    @creds = Base64.strict_encode64("#{username}:#{password}")
    @sid = nil
    @poll_thread = nil
    @ping_thread = nil
    @stop = false
    @ping_interval = 25

    @task_id = 'pending'
    @completed = false
    @question_pending = false
    @question_text = nil
    @file_dropped = false
    @chunks_received = 0
    @last_activity = Time.now
    @mx = Mutex.new
  end

  def connect
    uri = URI("#{@base_url}/socket.io/?EIO=4&transport=polling")
    resp = eio_get(uri)
    return false unless resp && resp.code == '200' && resp.body.start_with?('0{')

    data = JSON.parse(resp.body[1..])
    @sid = data['sid']
    @ping_interval = (data['pingInterval'] || 25_000) / 1000.0
    log('SIO', "Engine.IO connected (sid=#{@sid})")

    return false unless eio_post('40')

    ack = eio_get(poll_uri)
    if ack && ack.body&.start_with?('40')
      log('SIO', '✅ Connected to AiderDesk Socket.IO')
    else
      log('SIO', "Connect ack unexpected: #{ack&.body&.slice(0, 100)}")
    end

    sub = JSON.generate(['message', {
      'action' => 'subscribe-events',
      'eventTypes' => %w[response-chunk response-completed ask-question question-answered
                         user-message log tool context-files-updated task-completed task-cancelled],
      'baseDirs' => [@project_dir]
    }])
    eio_post("42#{sub}")
    log('SIO', "Subscribed to events for #{@project_dir}")

    @stop = false
    @poll_thread = Thread.new { poll_loop }
    @ping_thread = Thread.new { ping_loop }
    true
  rescue StandardError => e
    log('SIO', "❌ Connection failed: #{e}")
    false
  end

  def disconnect
    @stop = true
    @poll_thread&.join(3)
    @ping_thread&.join(3)
    eio_post('1') if @sid
  rescue StandardError
    nil
  end

  def update_task_id(new_id)
    @mx.synchronize do
      @task_id = new_id
      @completed = false
      @question_pending = false
      @question_text = nil
      @file_dropped = false
      @chunks_received = 0
      @last_activity = Time.now
    end
  end

  def completed?()        @mx.synchronize { @completed } end
  def question_pending?()  @mx.synchronize { @question_pending } end
  def question_text()     @mx.synchronize { @question_text } end
  def file_dropped?()     @mx.synchronize { @file_dropped } end
  def chunks_received()   @mx.synchronize { @chunks_received } end
  def last_activity()     @mx.synchronize { @last_activity } end
  def clear_question()    @mx.synchronize { @question_pending = false } end

  def snapshot
    @mx.synchronize do
      { completed: @completed, question_pending: @question_pending, question_text: @question_text,
        file_dropped: @file_dropped, chunks_received: @chunks_received, last_activity: @last_activity }
    end
  end

  private

  def poll_uri
    URI("#{@base_url}/socket.io/?EIO=4&transport=polling&sid=#{@sid}")
  end

  def eio_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 30
    http.open_timeout = 10
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Basic #{@creds}"
    http.request(req)
  rescue StandardError => e
    log('DEBUG', "EIO GET error: #{e}")
    nil
  end

  def eio_post(body)
    uri = poll_uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 10
    http.open_timeout = 10
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Basic #{@creds}"
    req['Content-Type'] = 'text/plain;charset=UTF-8'
    req.body = body
    http.request(req).code == '200'
  rescue StandardError => e
    log('DEBUG', "EIO POST error: #{e}")
    false
  end

  def poll_loop
    until @stop
      begin
        resp = eio_get(poll_uri)
        parse_packets(resp.body) if resp && resp.code == '200'
      rescue StandardError => e
        log('DEBUG', "Poll error: #{e}") unless @stop
        sleep 1
      end
    end
  end

  def ping_loop
    until @stop
      sleep @ping_interval
      break if @stop
      eio_post('3')
    end
  rescue StandardError
    nil
  end

  def parse_packets(raw)
    return if raw.nil? || raw.empty?
    packets = raw.include?("\x1e") ? raw.split("\x1e") : [raw]
    packets.each do |pkt|
      next if pkt.empty?
      case pkt[0]
      when '2' then eio_post('3')
      when '4' then handle_sio_packet(pkt[1..])
      end
    end
  end

  def handle_sio_packet(data)
    return unless data && data[0] == '2'
    arr = JSON.parse(data[1..])
    handle_event(arr[1]) if arr.is_a?(Array) && arr[0] == 'event'
  rescue JSON::ParserError
    nil
  end

  def handle_event(payload)
    return unless payload.is_a?(Hash)
    et = payload['type'] || 'unknown'
    d  = payload['data'] || {}
    tid = d['taskId'] || ''

    @mx.synchronize do
      return if !tid.empty? && tid != @task_id
      @last_activity = Time.now

      case et
      when 'response-chunk'
        @chunks_received += 1
        c = (d['content'] || d['chunk'] || '').to_s
        if @chunks_received <= 5 || (@chunks_received % 20).zero?
          log('SIO', "  [chunk ##{@chunks_received}] #{c[0, 100]}")
        end
        @file_dropped = true if c.downcase.include?('dropping')
      when 'response-completed'
        c = (d['content'] || '').to_s
        log('SIO', "  ✅ [response-completed] #{c[0, 150]}")
        @completed = true
      when 'ask-question'
        @question_text = (d['question'] || d['content'] || d.to_s).to_s[0, 200]
        @question_pending = true
        log('SIO', "  ❓ [ask-question] #{@question_text}")
      when 'question-answered'
        log('SIO', '  [question-answered]')
        @question_pending = false
      when 'log'
        c = (d['content'] || d['message'] || '').to_s
        log('SIO', "  [log/#{d['level'] || 'info'}] #{c[0, 120]}")
        @file_dropped = true if c.downcase.include?('dropping')
      when 'tool'
        log('SIO', "  [tool] #{(d['content'] || '').to_s[0, 120]}")
      when 'user-message'
        log('SIO', "  [user-message] #{(d['content'] || '').to_s[0, 120]}")
      when 'task-completed', 'task-cancelled'
        log('SIO', "  [#{et}]")
        @completed = true
      when 'context-files-updated'
        log('SIO', "  [context-files-updated] #{(d['files'] || []).length} file(s)")
      else
        log('DEBUG', "  [#{et}] (unhandled)")
      end
    end
  end
end

# ── REST polling monitor (fallback) ─────────────────────────────────────────

class RestMonitor
  def initialize(api_url:, project_dir:, username:, password:)
    @api_url = api_url
    @project_dir = project_dir
    @username = username
    @password = password
    @task_id = 'pending'
    @completed = false
    @question_pending = false
    @question_text = nil
    @file_dropped = false
    @chunks_received = 0
    @last_activity = Time.now
    @seen_ids = {}
  end

  def connect
    log('REST', 'Using REST polling transport (no real-time events)')
    true
  end

  def disconnect; end

  def update_task_id(new_id)
    @task_id = new_id
    @completed = false
    @question_pending = false
    @question_text = nil
    @file_dropped = false
    @chunks_received = 0
    @last_activity = Time.now
    @seen_ids = {}
  end

  def completed?()        @completed end
  def question_pending?()  @question_pending end
  def question_text()     @question_text end
  def file_dropped?()     @file_dropped end
  def chunks_received()   @chunks_received end
  def last_activity()     @last_activity end
  def clear_question()    @question_pending = false end

  def snapshot
    { completed: @completed, question_pending: @question_pending, question_text: @question_text,
      file_dropped: @file_dropped, chunks_received: @chunks_received, last_activity: @last_activity }
  end

  # Called once per loop iteration from the main thread
  def poll_once
    status, body = api_post(@api_url, '/project/tasks/load',
                            { projectDir: @project_dir, id: @task_id },
                            username: @username, password: @password)
    return unless status == 200

    messages = (parse_json(body) || {}).fetch('messages', [])
    messages.each do |msg|
      mid = msg['id'] || msg.object_id.to_s
      next if @seen_ids[mid]
      @seen_ids[mid] = true
      @last_activity = Time.now

      case msg['type']
      when 'response-chunk'
        @chunks_received += 1
        c = msg['content'].to_s
        if @chunks_received <= 5 || (@chunks_received % 20).zero?
          log('REST', "  [chunk ##{@chunks_received}] #{c[0, 100]}")
        end
        @file_dropped = true if c.downcase.include?('dropping')
      when 'response-completed'
        log('REST', "  ✅ [response-completed] #{msg['content'].to_s[0, 150]}")
        @completed = true
      when 'ask-question'
        @question_text = (msg['question'] || msg['content'] || msg.to_s).to_s[0, 200]
        @question_pending = true
        log('REST', "  ❓ [ask-question] #{@question_text}")
      when 'question-answered'
        @question_pending = false
      when 'task-completed', 'task-cancelled'
        log('REST', "  [#{msg['type']}]")
        @completed = true
      end
    end
  end
end

# ── CLI ──────────────────────────────────────────────────────────────────────

def parse_args(argv)
  args = {
    prompt: "Create a single file called calculate_pi.rb that calculates Pi to N decimal places, where N is passed as a command-line argument. Keep it simple — under 20 lines.",
    prompt_file: nil, model: 'ollama/qwen2.5-coder:32b', timeout: 120, retries: 3,
    mode: 'code', edit_format: nil, transport: 'socketio',
    base_url: 'http://localhost:24337', ollama_url: 'http://localhost:11434',
    username: 'admin', password: 'booberry',
    project_dir: '/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild',
    target_file: nil, debug: false, no_warmup: false, no_cleanup: false,
    no_tail_logs: false, warmup_timeout: 300
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
    opts.on('-p', '--prompt PROMPT', 'Prompt to send') { |v| args[:prompt] = v }
    opts.on('-f', '--prompt-file PATH', 'Path to prompt file (overrides --prompt)') { |v| args[:prompt_file] = v }
    opts.on('-m', '--model MODEL', 'Model identifier') { |v| args[:model] = v }
    opts.on('-t', '--timeout SECONDS', Integer, 'Seconds per attempt (default: 120)') { |v| args[:timeout] = v }
    opts.on('-r', '--retries COUNT', Integer, 'Max attempts (default: 3)') { |v| args[:retries] = v }
    opts.on('--mode MODE', 'Aider mode: code, agent, ask, architect') { |v| args[:mode] = v }
    opts.on('--edit-format FMT', 'Edit format: diff, whole, udiff, editor-diff, editor-whole') { |v| args[:edit_format] = v }
    opts.on('--transport TYPE', 'Transport: socketio (default) or rest') { |v| args[:transport] = v }
    opts.on('--base-url URL', 'AiderDesk base URL') { |v| args[:base_url] = v }
    opts.on('--ollama-url URL', 'Ollama API URL') { |v| args[:ollama_url] = v }
    opts.on('-u', '--username USER', 'AiderDesk username') { |v| args[:username] = v }
    opts.on('--password PASS', 'AiderDesk password') { |v| args[:password] = v }
    opts.on('--project-dir DIR', 'AiderDesk project directory') { |v| args[:project_dir] = v }
    opts.on('--target-file PATH', 'Expected output file path') { |v| args[:target_file] = v }
    opts.on('-d', '--debug', 'Enable verbose debug output') { args[:debug] = true }
    opts.on('--no-warmup', 'Skip Ollama warm-up') { args[:no_warmup] = true }
    opts.on('--no-cleanup', 'Skip deleting existing tasks') { args[:no_cleanup] = true }
    opts.on('--no-tail-logs', 'Disable log tailing') { args[:no_tail_logs] = true }
    opts.on('--warmup-timeout SEC', Integer, 'Warm-up timeout (default: 300)') { |v| args[:warmup_timeout] = v }
    opts.on('-h', '--help', 'Show help') { puts opts; exit 0 }
  end.parse!(argv)
  args
end

# ── Main ─────────────────────────────────────────────────────────────────────

def main
  args = parse_args(ARGV)
  $debug = args[:debug]

  api_url     = "#{args[:base_url]}/api"
  project_dir = args[:project_dir]
  model       = args[:model]
  prompt      = args[:prompt]
  timeout     = args[:timeout]
  max_attempts = args[:retries]
  mode        = args[:mode]
  target_file = args[:target_file]
  transport   = args[:transport]

  if args[:prompt_file]
    path = File.expand_path(args[:prompt_file])
    unless File.exist?(path)
      log('FAIL', "Prompt file not found: #{path}")
      exit 1
    end
    prompt = File.read(path).strip
    if prompt.empty?
      log('FAIL', "Prompt file is empty: #{path}")
      exit 1
    end
    log('INFO', "Loaded prompt from file: #{path} (#{prompt.length} chars)")
  end

  phases = {}

  puts '=' * 70
  log('INFO', 'AiderDesk + Ollama Prompt Runner (Ruby)')
  log('INFO', "Model:        #{model}")
  log('INFO', "Timeout:      #{timeout}s per attempt")
  log('INFO', "Max attempts: #{max_attempts}")
  log('INFO', "Mode:         #{mode}")
  log('INFO', "Transport:    #{transport}")
  log('INFO', "Edit format:  #{args[:edit_format] || '(server default)'}")
  log('INFO', "Prompt:       #{prompt[0, 80]}#{prompt.length > 80 ? '...' : ''}")
  log('INFO', "Target file:  #{target_file}") if target_file
  log('INFO', "Debug:        #{$debug}")
  puts '=' * 70

  # ── AiderDesk health ───────────────────────────────────────────────────
  t0 = Time.now
  status, = api_get(api_url, '/settings', username: args[:username], password: args[:password], timeout: 5)
  unless status == 200
    log('FAIL', "Cannot reach AiderDesk at #{args[:base_url]}")
    exit 1
  end
  log('PASS', 'AiderDesk is reachable')
  phases[:aiderdesk_health] = (Time.now - t0).round(2)

  # ── Ollama health ──────────────────────────────────────────────────────
  t0 = Time.now
  unless check_ollama_health(model, args[:ollama_url])
    log('FAIL', 'Ollama not available — exiting')
    exit 1
  end
  check_ollama_running_models(args[:ollama_url])
  phases[:ollama_health] = (Time.now - t0).round(2)

  # ── Warm-up ────────────────────────────────────────────────────────────
  unless args[:no_warmup]
    t0 = Time.now
    warm_up_ollama(model, timeout: args[:warmup_timeout], ollama_url: args[:ollama_url])
    phases[:warm_up] = (Time.now - t0).round(2)
  else
    log('INFO', 'Skipping Ollama warm-up (--no-warmup)')
  end

  # ── Log tailers ────────────────────────────────────────────────────────
  ollama_stop = { stop: false }
  aiderdesk_stop = { stop: false }
  unless args[:no_tail_logs]
    ollama_log = File.expand_path('~/.ollama/logs/server.log')
    aiderdesk_log = File.expand_path("~/Library/Application Support/aider-desk-dev/logs/combined-#{Time.now.strftime('%Y-%m-%d')}.log")
    ollama_stop = start_log_tailer(ollama_log, 'OLLAMA')
    aiderdesk_stop = start_log_tailer(aiderdesk_log, 'AIDESK')
  end

  # ── Project setup ──────────────────────────────────────────────────────
  t0 = Time.now
  api_post(api_url, '/project/add-open', { projectDir: project_dir }, username: args[:username], password: args[:password])
  api_post(api_url, '/project/set-active', { projectDir: project_dir }, username: args[:username], password: args[:password])
  log('INFO', "Project set active: #{project_dir}")

  if args[:edit_format]
    log('INFO', "Setting edit format to '#{args[:edit_format]}' for #{model}")
    api_post(api_url, '/project/settings/edit-formats',
             { projectDir: project_dir, updatedFormats: { model => args[:edit_format] } },
             username: args[:username], password: args[:password])
  end

  api_post(api_url, '/project/settings/update',
           { projectDir: project_dir, autoApprove: true },
           username: args[:username], password: args[:password])

  unless args[:no_cleanup]
    log('INFO', 'Deleting all existing tasks...')
    s, b = api_get(api_url, "/project/tasks?projectDir=#{URI.encode_www_form_component(project_dir)}",
                   username: args[:username], password: args[:password])
    if s == 200
      tasks = parse_json(b) || []
      tasks.each do |t|
        tid = t['id']
        api_post(api_url, '/project/tasks/delete', { projectDir: project_dir, id: tid },
                 username: args[:username], password: args[:password]) if tid
      end
      log('PASS', "Deleted #{tasks.length} task(s)") if tasks.any?
    end
    sleep 2
  end
  phases[:setup] = (Time.now - t0).round(2)

  # ── Remove target file ─────────────────────────────────────────────────
  if target_file && File.exist?(target_file)
    File.delete(target_file)
    log('PASS', "Removed pre-existing #{target_file}")
  end

  # ── Connect monitor ────────────────────────────────────────────────────
  monitor = if transport == 'socketio'
              SocketIOMonitor.new(base_url: args[:base_url], project_dir: project_dir,
                                  username: args[:username], password: args[:password])
            else
              RestMonitor.new(api_url: api_url, project_dir: project_dir,
                              username: args[:username], password: args[:password])
            end

  unless monitor.connect
    log('FAIL', 'Could not connect event monitor')
    exit 1
  end

  # ── Attempt loop ───────────────────────────────────────────────────────
  task_id = nil
  completed = false
  file_exists = false
  total_start = Time.now

  (1..max_attempts).each do |attempt|
    puts "\n" + ('━' * 70)
    log('INFO', "  ATTEMPT #{attempt} of #{max_attempts}")
    puts '━' * 70

    check_ollama_running_models(args[:ollama_url])

    t0 = Time.now
    task_name = "Prompt ##{attempt} - #{Time.now.strftime('%H:%M:%S')}"
    s, b = api_post(api_url, '/project/tasks/new',
                    { projectDir: project_dir, name: task_name, activate: true },
                    username: args[:username], password: args[:password])
    if s != 200
      log('FAIL', "Could not create task: #{s} #{b.to_s[0, 200]}")
      next
    end

    task_id = parse_json(b)&.fetch('id', nil)
    log('PASS', "Task created: #{task_id}")
    monitor.update_task_id(task_id)

    api_post(api_url, '/project/settings/main-model',
             { projectDir: project_dir, taskId: task_id, mainModel: model },
             username: args[:username], password: args[:password])
    api_post(api_url, '/project/tasks',
             { projectDir: project_dir, id: task_id, updates: { autoApprove: true, currentMode: mode } },
             username: args[:username], password: args[:password])
    log('INFO', "Model=#{model}, autoApprove=true, mode=#{mode}")
    phases[:task_creation] = (Time.now - t0).round(2)

    if target_file
      File.delete(target_file) if File.exist?(target_file)
      basename = File.basename(target_file)
      log('INFO', "Pre-creating empty #{basename}")
      File.write(target_file, '')
      api_post(api_url, '/add-context-file',
               { projectDir: project_dir, taskId: task_id, path: basename, readOnly: false },
               username: args[:username], password: args[:password])
    end

    sleep 3

    log('INFO', "Submitting prompt (#{prompt.length} chars)...")
    prompt_result = fire_prompt_async(api_url, args[:username], args[:password], project_dir, task_id, prompt, mode)
    log('INFO', "Waiting up to #{timeout}s for completion...")
    puts '-' * 70

    attempt_start = Time.now
    attempt_completed = false
    file_on_disk = false
    first_chunk_time = nil

    loop do
      elapsed = Time.now - attempt_start

      # REST transport needs explicit polling
      monitor.poll_once if monitor.is_a?(RestMonitor)

      # Track first chunk
      if monitor.chunks_received > 0 && first_chunk_time.nil?
        first_chunk_time = elapsed.round(2)
        phases[:first_chunk] = first_chunk_time
      end

      if monitor.completed?
        log('PASS', "✅ response-completed received after #{elapsed.round(1)}s")
        log('INFO', "  Total chunks received: #{monitor.chunks_received}")
        phases[:completion] = elapsed.round(2)
        attempt_completed = true
        break
      end

      if monitor.question_pending?
        log('QUESTION', "Task asking: #{monitor.question_text}")
        log('QUESTION', "Auto-answering: 'yes'")
        api_post(api_url, '/project/answer-question',
                 { projectDir: project_dir, taskId: task_id, answer: 'yes' },
                 username: args[:username], password: args[:password])
        monitor.clear_question
      end

      if target_file && !file_on_disk && File.exist?(target_file) && File.size(target_file).positive?
        log('INFO', "📄 #{File.basename(target_file)} has content on disk")
        file_on_disk = true
        file_exists = true
        phases[:file_on_disk] = elapsed.round(2)
      end

      if monitor.file_dropped? && file_on_disk
        log('DETECT', '✅ File created + dropped from chat — early success')
        api_post(api_url, '/project/interrupt',
                 { projectDir: project_dir, taskId: task_id },
                 username: args[:username], password: args[:password])
        attempt_completed = true
        break
      end

      if monitor.chunks_received > 0
        stale = Time.now - monitor.last_activity
        log('WARN', "No new chunks for #{stale.round}s — may have stalled") if stale > STALE_CHUNK_TIMEOUT
      end

      if prompt_result[:done] && !monitor.completed?
        log(prompt_result[:error] ? 'WARN' : 'INFO',
            prompt_result[:error] ? "run-prompt error: #{prompt_result[:error]}" : "run-prompt returned HTTP #{prompt_result[:status]}")
        sleep 2
        if monitor.completed?
          attempt_completed = true
          break
        end
        if target_file && File.exist?(target_file) && File.size(target_file).positive?
          log('INFO', 'run-prompt finished + file has content — treating as success')
          file_exists = true
          attempt_completed = true
          break
        end
      end

      if elapsed > timeout
        snap = monitor.snapshot
        reason = classify_failure(snap, prompt_result, elapsed)
        puts ''
        log('TIMEOUT', "⚠️  No completion within #{timeout}s.")
        log('TIMEOUT', "  Failure reason:  #{reason}")
        log('TIMEOUT', "  Chunks received: #{snap[:chunks_received]}")
        log('TIMEOUT', "  Stale for:       #{(Time.now - snap[:last_activity]).round(1)}s")
        check_ollama_running_models(args[:ollama_url])
        api_post(api_url, '/project/interrupt',
                 { projectDir: project_dir, taskId: task_id },
                 username: args[:username], password: args[:password])
        sleep 2
        break
      end

      sleep 1
    end

    if attempt_completed || file_exists
      completed = true
      break
    end

    log('INFO', 'Waiting 5s before next attempt...') if attempt < max_attempts
    sleep 5 if attempt < max_attempts
  end

  # ── Final results ──────────────────────────────────────────────────────
  total_elapsed = (Time.now - total_start).round(1)
  file_exists = File.exist?(target_file) && File.size(target_file).positive? if target_file && !file_exists

  puts "\n" + ('=' * 70)
  log('INFO', '  FINAL RESULTS')
  puts '=' * 70
  log('INFO', "  Total elapsed:     #{total_elapsed}s")
  log('INFO', "  Task ID:           #{task_id}")
  log('INFO', "  Completed signal:  #{completed}")
  log('INFO', "  Transport:         #{transport}")
  log('INFO', "  File created:      #{file_exists}") if target_file
  log('INFO', "  Chunks received:   #{monitor.chunks_received}")

  if phases.any?
    puts ''
    log('INFO', '  Phase timing (seconds):')
    phases.each { |p, d| log('INFO', format('    %-20s %8.2fs', p, d)) }
  end
  puts ''

  ollama_stop[:stop] = true
  aiderdesk_stop[:stop] = true
  monitor.disconnect

  if completed || file_exists
    log('PASS', '✅ Prompt processed successfully.')
    if target_file && file_exists
      puts "\n--- #{File.basename(target_file)} (first 30 lines) ---"
      begin
        File.readlines(target_file).first(30).each { |l| puts "  #{l}" }
      rescue StandardError => e
        log('WARN', "Could not read file: #{e}")
      end
    end
    exit 0
  else
    log('FAIL', "❌ All #{max_attempts} attempts failed.")
    puts ''
    log('INFO', '  Troubleshooting:')
    log('INFO', '    1. Check Ollama: ollama ps')
    log('INFO', '    2. Try --transport rest for REST fallback')
    log('INFO', '    3. Try --no-warmup if warm-up hangs')
    log('INFO', '    4. Try --edit-format whole')
    exit 1
  end
end

main if __FILE__ == $PROGRAM_NAME
