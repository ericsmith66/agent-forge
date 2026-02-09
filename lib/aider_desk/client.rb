# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'logger'

require_relative 'api_error'

module AiderDesk
  # Structured wrapper around Net::HTTP responses
  class Response
    attr_reader :status, :body, :error

    def initialize(http_response: nil, error: nil)
      if http_response
        @status = http_response.code.to_i
        @body = http_response.body
        @error = nil
      else
        @status = 0
        @body = nil
        @error = error
      end
    end

    def success?
      @error.nil? && @status >= 200 && @status < 300
    end

    def data
      @data ||= begin
        JSON.parse(@body) if @body && !@body.empty?
      rescue JSON::ParserError
        nil
      end
    end

    def to_s
      if success?
        "Response(#{@status})"
      else
        "Response(#{@status}, error=#{@error || data&.dig('error') || @body})"
      end
    end
  end

  # Main AiderDesk API client.
  #
  # Defaults to preview_only: true — no edits are applied without explicit override.
  # Thread-safe: all state is instance-level, no class-level mutable state.
  #
  # Configuration priority:
  #   1. Explicit keyword arguments
  #   2. Rails.application.credentials.dig(:aider_desk) (if Rails is loaded)
  #   3. Environment variables (AIDER_BASE_URL, AIDER_USERNAME, AIDER_PASSWORD, AIDER_PROJECT_DIR)
  #   4. Defaults
  class Client
    FORCE_APPLY = false

    attr_reader :base_url, :project_dir, :preview_only

    def initialize(base_url: nil, username: nil, password: nil, project_dir: nil,
                   logger: nil, raise_on_error: false, preview_only: true,
                   read_timeout: 300, open_timeout: 30)
      creds = load_credentials
      @base_url       = (base_url || creds[:url] || ENV['AIDER_BASE_URL'] || 'http://localhost:24337').chomp('/')
      @username        = username || creds[:username] || ENV['AIDER_USERNAME']
      @password        = password || creds[:password] || ENV['AIDER_PASSWORD']
      @project_dir     = project_dir || creds[:default_project_dir] || ENV['AIDER_PROJECT_DIR']
      @raise_on_error  = raise_on_error
      @preview_only    = preview_only
      @read_timeout    = read_timeout
      @open_timeout    = open_timeout
      @logger          = logger || default_logger
    end

    # ─── Health ────────────────────────────────────────────────────────────

    # Quick health check. Returns hash with :ok and :data keys.
    def health
      res = get_settings
      if res.success?
        { ok: true, status: res.status, data: res.data }
      elsif res.status == 401
        # 401 means AiderDesk is reachable but requires authentication
        { ok: true, status: res.status, data: nil, warning: 'Authentication required — set credentials' }
      else
        { ok: false, status: res.status, error: res.error || res.body }
      end
    rescue => e
      { ok: false, status: 0, error: e.message }
    end

    # Boolean health check — true if AiderDesk is reachable (even if auth is needed)
    def health_check
      health[:ok]
    end

    # ─── Settings ──────────────────────────────────────────────────────────

    def get_settings
      get('/api/settings')
    end

    def update_settings(settings)
      post('/api/settings', body: settings)
    end

    # ─── Projects ──────────────────────────────────────────────────────────

    def get_projects
      get('/api/projects')
    end

    def add_open_project(project_dir: resolve_project_dir)
      post('/api/project/add-open', body: { "projectDir" => project_dir })
    end

    def remove_open_project(project_dir: resolve_project_dir)
      post('/api/project/remove-open', body: { "projectDir" => project_dir })
    end

    def get_project_settings(project_dir: resolve_project_dir)
      get('/api/project/settings', params: { projectDir: project_dir })
    end

    def start_project(project_dir: resolve_project_dir)
      post('/api/project/start', body: { "projectDir" => project_dir })
    end

    def stop_project(project_dir: resolve_project_dir)
      post('/api/project/stop', body: { "projectDir" => project_dir })
    end

    def restart_project(project_dir: resolve_project_dir)
      post('/api/project/restart', body: { "projectDir" => project_dir })
    end

    # ─── Tasks ─────────────────────────────────────────────────────────────

    def create_task(name: nil, parent_id: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "parentId" => parent_id }
      body["name"] = name if name
      post('/api/project/tasks/new', body: body)
    end

    # Convenience: create a task and return just the task ID string.
    def create_task_and_get_id(name: nil, project_dir: resolve_project_dir)
      res = create_task(name: name, project_dir: project_dir)
      return nil unless res.success?

      res.data&.dig("id")
    end

    def list_tasks(project_dir: resolve_project_dir)
      get('/api/project/tasks', params: { projectDir: project_dir })
    end

    def load_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/load', body: {
        "projectDir" => project_dir,
        "id"         => task_id
      })
    end

    def delete_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/delete', body: {
        "projectDir" => project_dir,
        "id"         => task_id
      })
    end

    def task_status(task_id:, project_dir: resolve_project_dir)
      res = load_task(task_id: task_id, project_dir: project_dir)
      return nil unless res.success?

      res.data
    end

    def task_messages(task_id:, project_dir: resolve_project_dir)
      res = load_task(task_id: task_id, project_dir: project_dir)
      return [] unless res.success?

      res.data&.fetch("messages", []) || []
    end

    # ─── Prompts ───────────────────────────────────────────────────────────

    def run_prompt(task_id:, prompt:, mode: "agent", project_dir: resolve_project_dir)
      post('/api/run-prompt', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "prompt"     => prompt,
        "mode"       => mode
      })
    end

    # Run a prompt and poll until completion or timeout.
    # Yields new messages to an optional block for streaming/logging.
    # Returns the final Response from load_task, or a hash with status: :timeout.
    def run_prompt_and_wait(task_id:, prompt:, mode: "agent", timeout: 120,
                           poll_interval: 5, project_dir: resolve_project_dir, &block)
      res = run_prompt(task_id: task_id, prompt: prompt, mode: mode, project_dir: project_dir)
      return res unless res.success?

      start_time = Time.now
      last_msg_count = 0

      loop do
        elapsed = Time.now - start_time
        if elapsed >= timeout
          @logger.warn { "run_prompt_and_wait timed out after #{timeout}s for task #{task_id}" }
          final = load_task(task_id: task_id, project_dir: project_dir)
          return { response: final, status: :timeout }
        end

        load_res = load_task(task_id: task_id, project_dir: project_dir)
        if load_res.success? && load_res.data
          messages = load_res.data.fetch("messages", [])
          current_count = messages.length

          if current_count > last_msg_count
            new_msgs = messages[last_msg_count..]
            new_msgs.each { |m| block.call(m) } if block

            if new_msgs.any? { |m| m["type"] == "response-completed" }
              return load_res
            end

            last_msg_count = current_count
          end
        end

        sleep poll_interval
      end
    end

    # Convenience: create task + run prompt + wait. Returns a hash.
    def run_and_wait(prompt:, name: nil, mode: "agent", timeout: 120,
                     poll_interval: 5, project_dir: resolve_project_dir, &block)
      task_res = create_task(name: name, project_dir: project_dir)
      unless task_res.success?
        return { task_id: nil, response: task_res, messages: [] }
      end

      task_id = task_res.data["id"]
      collected_messages = []

      final_res = run_prompt_and_wait(
        task_id: task_id,
        prompt: prompt,
        mode: mode,
        timeout: timeout,
        poll_interval: poll_interval,
        project_dir: project_dir
      ) do |msg|
        collected_messages << msg
        block.call(msg) if block
      end

      {
        task_id:  task_id,
        response: final_res,
        messages: collected_messages
      }
    end

    # ─── Context Files ─────────────────────────────────────────────────────

    def add_context_file(task_id:, path:, read_only: false, project_dir: resolve_project_dir)
      post('/api/add-context-file', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "path"       => path,
        "readOnly"   => read_only
      })
    end

    def drop_context_file(task_id:, path:, project_dir: resolve_project_dir)
      post('/api/drop-context-file', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "path"       => path
      })
    end

    def get_context_files(task_id:, project_dir: resolve_project_dir)
      post('/api/get-context-files', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    # ─── Apply Edits (guarded by preview_only) ─────────────────────────────

    def apply_edits(task_id:, edits:, project_dir: resolve_project_dir)
      if @preview_only && !FORCE_APPLY
        @logger.info { "apply_edits blocked: preview_only is true. Set preview_only: false to apply." }
        return Response.new(error: "Blocked: preview_only mode. No edits applied.")
      end

      post('/api/project/apply-edits', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "edits"      => edits
      })
    end

    # ─── Model Settings ────────────────────────────────────────────────────

    def set_main_model(task_id:, main_model:, project_dir: resolve_project_dir)
      post('/api/project/settings/main-model', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "mainModel"  => main_model
      })
    end

    # ─── Conversation ──────────────────────────────────────────────────────

    def interrupt(task_id:, project_dir: resolve_project_dir)
      post('/api/project/interrupt', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def clear_context(task_id:, project_dir: resolve_project_dir)
      post('/api/project/clear-context', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    private

    # Try to load credentials from Rails encrypted credentials, silently fall back
    def load_credentials
      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        creds = Rails.application.credentials.dig(:aider_desk)
        return creds if creds.is_a?(Hash)
      end
      {}
    rescue => e
      @logger&.debug { "Could not load Rails credentials: #{e.message}" }
      {}
    end

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger
      else
        Logger.new($stdout, level: Logger::WARN)
      end
    end

    def resolve_project_dir(override = nil)
      override || @project_dir || raise(ArgumentError, "project_dir is required — set it on Client.new or pass it explicitly")
    end

    # ─── HTTP Transport ────────────────────────────────────────────────────

    def get(path, params: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute(uri, request)
    end

    def post(path, body: {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = body.to_json
      execute(uri, request)
    end

    def patch(path, body: {})
      uri = build_uri(path)
      request = Net::HTTP::Patch.new(uri)
      request.content_type = "application/json"
      request.body = body.to_json
      execute(uri, request)
    end

    def build_uri(path, params = {})
      uri = URI("#{@base_url}#{path}")
      unless params.empty?
        query = params.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v)}" }.join('&')
        uri.query = query
      end
      uri
    end

    def execute(uri, request)
      @logger.debug { "#{request.method} #{uri}" }

      request.basic_auth(@username, @password) if @username && @password

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
      http_response = http.request(request)

      @logger.debug { "Response #{http_response.code}: #{http_response.body&.slice(0, 200)}" }

      response = Response.new(http_response: http_response)

      # Raise specific errors for known failure codes
      if response.status == 401
        raise AuthError.new(response) if @raise_on_error
      elsif !response.success? && @raise_on_error
        raise ApiError.new(response)
      end

      response
    rescue AuthError, ApiError
      raise
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, SocketError => e
      @logger.error { "Connection failed: #{e.message}" }
      raise ConnectionError.new(@base_url, e) if @raise_on_error
      Response.new(error: "Connection failed: #{e.message}")
    rescue => e
      @logger.error { "Request failed: #{e.message}" }
      response = Response.new(error: e.message)
      raise ApiError.new(response) if @raise_on_error
      response
    end
  end
end
