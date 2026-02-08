require 'net/http'
require 'json'
require 'uri'
require 'logger'
require 'yaml'

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

  # Custom error raised when raise_on_error: true
  class ApiError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      super("AiderDesk API error #{response.status}: #{response.error || response.body}")
    end
  end

  # Main API client
  class Client
    attr_reader :base_url, :project_dir

    def initialize(base_url: nil, username: nil, password: nil, project_dir: nil, logger: nil, raise_on_error: false, read_timeout: 300, open_timeout: 30)
      @base_url       = (base_url || ENV['AIDER_BASE_URL'] || 'http://localhost:24337').chomp('/')
      @username        = username || ENV['AIDER_USERNAME']
      @password        = password || ENV['AIDER_PASSWORD']
      @project_dir     = project_dir || ENV['AIDER_PROJECT_DIR']
      @raise_on_error  = raise_on_error
      @read_timeout    = read_timeout
      @open_timeout    = open_timeout
      @logger          = logger || Logger.new($stdout, level: Logger::WARN)
    end

    # ─── System ──────────────────────────────────────────────────────────

    def get_env_var(key:, base_dir: nil)
      params = { key: key }
      params[:baseDir] = base_dir if base_dir
      get('/api/system/env-var', params: params)
    end

    # ─── Settings ────────────────────────────────────────────────────────

    def get_settings
      get('/api/settings')
    end

    def update_settings(settings)
      post('/api/settings', body: settings)
    end

    def get_recent_projects
      get('/api/settings/recent-projects')
    end

    def add_recent_project(project_dir: resolve_project_dir)
      post('/api/settings/add-recent-project', body: { "projectDir" => project_dir })
    end

    def remove_recent_project(project_dir: resolve_project_dir)
      post('/api/settings/remove-recent-project', body: { "projectDir" => project_dir })
    end

    def set_zoom(level:)
      post('/api/settings/zoom', body: { "level" => level })
    end

    def get_versions(force_refresh: false)
      params = {}
      params[:forceRefresh] = 'true' if force_refresh
      get('/api/versions', params: params)
    end

    def download_latest
      post('/api/download-latest', body: {})
    end

    def get_release_notes
      get('/api/release-notes')
    end

    def clear_release_notes
      post('/api/clear-release-notes', body: {})
    end

    def get_os
      get('/api/os')
    end

    # ─── Prompts ─────────────────────────────────────────────────────────

    def run_prompt(task_id:, prompt:, mode: "agent", project_dir: resolve_project_dir)
      post('/api/run-prompt', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "prompt"     => prompt,
        "mode"       => mode
      })
    end

    def save_prompt(task_id:, prompt:, project_dir: resolve_project_dir)
      post('/api/save-prompt', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "prompt"     => prompt
      })
    end

    # ─── Context Files ───────────────────────────────────────────────────

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

    def get_addable_files(task_id:, search_regex: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id }
      body["searchRegex"] = search_regex if search_regex
      post('/api/get-addable-files', body: body)
    end

    def get_all_files(task_id:, use_git: false, project_dir: resolve_project_dir)
      post('/api/get-all-files', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "useGit"     => use_git
      })
    end

    # ─── Custom Commands ─────────────────────────────────────────────────

    def get_custom_commands(project_dir: resolve_project_dir)
      get('/api/project/custom-commands', params: { projectDir: project_dir })
    end

    def run_custom_command(task_id:, command_name:, args: [], mode: "agent", project_dir: resolve_project_dir)
      post('/api/project/custom-commands', body: {
        "projectDir"  => project_dir,
        "taskId"      => task_id,
        "commandName" => command_name,
        "args"        => args,
        "mode"        => mode
      })
    end

    # ─── Projects ────────────────────────────────────────────────────────

    def get_projects
      get('/api/projects')
    end

    def get_input_history(project_dir: resolve_project_dir)
      get('/api/project/input-history', params: { projectDir: project_dir })
    end

    def add_open_project(project_dir: resolve_project_dir)
      post('/api/project/add-open', body: { "projectDir" => project_dir })
    end

    def remove_open_project(project_dir: resolve_project_dir)
      post('/api/project/remove-open', body: { "projectDir" => project_dir })
    end

    def set_active_project(project_dir: resolve_project_dir)
      post('/api/project/set-active', body: { "projectDir" => project_dir })
    end

    def restart_project(project_dir: resolve_project_dir)
      post('/api/project/restart', body: { "projectDir" => project_dir })
    end

    def start_project(project_dir: resolve_project_dir)
      post('/api/project/start', body: { "projectDir" => project_dir })
    end

    def stop_project(project_dir: resolve_project_dir)
      post('/api/project/stop', body: { "projectDir" => project_dir })
    end

    def update_project_order(project_dirs:)
      post('/api/project/update-order', body: { "projectDirs" => project_dirs })
    end

    def get_project_settings(project_dir: resolve_project_dir)
      get('/api/project/settings', params: { projectDir: project_dir })
    end

    def update_project_settings(project_dir: resolve_project_dir, **settings)
      patch('/api/project/settings', body: { "projectDir" => project_dir }.merge(settings))
    end

    def validate_path(path:, project_dir: resolve_project_dir)
      post('/api/project/validate-path', body: {
        "projectDir" => project_dir,
        "path"       => path
      })
    end

    def is_project_path(path:)
      post('/api/project/is-project-path', body: { "path" => path })
    end

    def file_suggestions(current_path:, directories_only: false)
      post('/api/project/file-suggestions', body: {
        "currentPath"     => current_path,
        "directoriesOnly" => directories_only
      })
    end

    def paste_image(task_id:, base64_image_data: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id }
      body["base64ImageData"] = base64_image_data if base64_image_data
      post('/api/project/paste-image', body: body)
    end

    def apply_edits(task_id:, edits:, project_dir: resolve_project_dir)
      post('/api/project/apply-edits', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "edits"      => edits
      })
    end

    def run_command(task_id:, command:, project_dir: resolve_project_dir)
      post('/api/project/run-command', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "command"    => command
      })
    end

    def init_rules(task_id:, project_dir: resolve_project_dir)
      post('/api/project/init-rules', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def scrape_web(task_id:, url:, file_path: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id, "url" => url }
      body["filePath"] = file_path if file_path
      post('/api/project/scrape-web', body: body)
    end

    # ─── Tasks ───────────────────────────────────────────────────────────

    def create_task(name: nil, parent_id: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "parentId" => parent_id }
      body["name"] = name if name
      post('/api/project/tasks/new', body: body)
    end

    def update_task(task_id:, updates:, project_dir: resolve_project_dir)
      post('/api/project/tasks', body: {
        "projectDir" => project_dir,
        "id"         => task_id,
        "updates"    => updates
      })
    end

    def load_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/load', body: {
        "projectDir" => project_dir,
        "id"         => task_id
      })
    end

    def list_tasks(project_dir: resolve_project_dir)
      get('/api/project/tasks', params: { projectDir: project_dir })
    end

    def delete_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/delete', body: {
        "projectDir" => project_dir,
        "id"         => task_id
      })
    end

    def duplicate_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/duplicate', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def fork_task(task_id:, message_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/fork', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "messageId"  => message_id
      })
    end

    def reset_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/reset', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def export_task_markdown(task_id:, project_dir: resolve_project_dir)
      post('/api/project/tasks/export-markdown', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def resume_task(task_id:, project_dir: resolve_project_dir)
      post('/api/project/resume-task', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    # ─── Messages ────────────────────────────────────────────────────────

    def remove_last_message(task_id:, project_dir: resolve_project_dir)
      post('/api/project/remove-last-message', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def remove_message(task_id:, message_id:, project_dir: resolve_project_dir)
      delete('/api/project/remove-message', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "messageId"  => message_id
      })
    end

    def remove_messages_up_to(task_id:, message_id:, project_dir: resolve_project_dir)
      delete('/api/project/remove-messages-up-to', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "messageId"  => message_id
      })
    end

    # ─── Conversation ────────────────────────────────────────────────────

    def redo_prompt(task_id:, mode:, updated_prompt: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id, "mode" => mode }
      body["updatedPrompt"] = updated_prompt if updated_prompt
      post('/api/project/redo-prompt', body: body)
    end

    def compact_conversation(task_id:, mode:, custom_instructions: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id, "mode" => mode }
      body["customInstructions"] = custom_instructions if custom_instructions
      post('/api/project/compact-conversation', body: body)
    end

    def handoff_conversation(task_id:, focus: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id }
      body["focus"] = focus if focus
      post('/api/project/handoff-conversation', body: body)
    end

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

    def answer_question(task_id:, answer:, project_dir: resolve_project_dir)
      post('/api/project/answer-question', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "answer"     => answer
      })
    end

    # ─── Model Settings ──────────────────────────────────────────────────

    def set_main_model(task_id:, main_model:, project_dir: resolve_project_dir)
      post('/api/project/settings/main-model', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "mainModel"  => main_model
      })
    end

    def set_weak_model(task_id:, weak_model:, project_dir: resolve_project_dir)
      post('/api/project/settings/weak-model', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id,
        "weakModel"  => weak_model
      })
    end

    def set_architect_model(task_id:, architect_model:, project_dir: resolve_project_dir)
      post('/api/project/settings/architect-model', body: {
        "projectDir"     => project_dir,
        "taskId"         => task_id,
        "architectModel" => architect_model
      })
    end

    def set_edit_formats(edit_formats:, project_dir: resolve_project_dir)
      post('/api/project/settings/edit-formats', body: {
        "projectDir"  => project_dir,
        "editFormats" => edit_formats
      })
    end

    # ─── Worktrees ───────────────────────────────────────────────────────

    def worktree_merge_to_main(task_id:, squash: true, target_branch: nil, commit_message: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id, "squash" => squash }
      body["targetBranch"]  = target_branch  if target_branch
      body["commitMessage"] = commit_message if commit_message
      post('/api/project/worktree/merge-to-main', body: body)
    end

    def worktree_apply_uncommitted(task_id:, target_branch: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id }
      body["targetBranch"] = target_branch if target_branch
      post('/api/project/worktree/apply-uncommitted', body: body)
    end

    def worktree_revert_last_merge(task_id:, project_dir: resolve_project_dir)
      post('/api/project/worktree/revert-last-merge', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def worktree_branches(project_dir: resolve_project_dir)
      get('/api/project/worktree/branches', params: { projectDir: project_dir })
    end

    def worktree_status(task_id:, target_branch: nil, project_dir: resolve_project_dir)
      params = { projectDir: project_dir, taskId: task_id }
      params[:targetBranch] = target_branch if target_branch
      get('/api/project/worktree/status', params: params)
    end

    def worktree_rebase_from_branch(task_id:, from_branch: nil, project_dir: resolve_project_dir)
      body = { "projectDir" => project_dir, "taskId" => task_id }
      body["fromBranch"] = from_branch if from_branch
      post('/api/project/worktree/rebase-from-branch', body: body)
    end

    def worktree_abort_rebase(task_id:, project_dir: resolve_project_dir)
      post('/api/project/worktree/abort-rebase', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def worktree_continue_rebase(task_id:, project_dir: resolve_project_dir)
      post('/api/project/worktree/continue-rebase', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    def worktree_resolve_conflicts(task_id:, project_dir: resolve_project_dir)
      post('/api/project/worktree/resolve-conflicts-with-agent', body: {
        "projectDir" => project_dir,
        "taskId"     => task_id
      })
    end

    # ─── High-Level Convenience Methods ──────────────────────────────────

    # Quick boolean health check
    def health_check
      get_settings.success?
    rescue
      false
    end

    # Run a prompt and poll until completion or timeout.
    # Yields new messages to an optional block.
    # Returns the final Response from load_task.
    def run_prompt_and_wait(task_id:, prompt:, mode: "agent", timeout: 120, poll_interval: 5, project_dir: resolve_project_dir, &block)
      res = run_prompt(task_id: task_id, prompt: prompt, mode: mode, project_dir: project_dir)
      return res unless res.success?

      start_time = Time.now
      last_msg_count = 0

      loop do
        elapsed = Time.now - start_time
        break if elapsed >= timeout

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

      # Timeout — return last load
      load_task(task_id: task_id, project_dir: project_dir)
    end

    # Create a task, run a prompt, and wait for completion. Returns a hash.
    def create_task_and_run(prompt:, name: nil, mode: "agent", timeout: 120, poll_interval: 5, project_dir: resolve_project_dir, &block)
      task_res = create_task(name: name, project_dir: project_dir)
      return { task_id: nil, response: task_res, messages: [] } unless task_res.success?

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

    private

    # Resolve project_dir, raising if not available
    def resolve_project_dir(override = nil)
      override || @project_dir || raise(ArgumentError, "project_dir is required — set it on Client.new or pass it explicitly")
    end

    # ─── HTTP Transport ──────────────────────────────────────────────────

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

    def delete(path, body: {})
      uri = build_uri(path)
      request = Net::HTTP::Delete.new(uri)
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

      if @username && @password
        request.basic_auth(@username, @password)
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
      http_response = http.request(request)

      @logger.debug { "Response #{http_response.code}: #{http_response.body&.slice(0, 200)}" }

      response = Response.new(http_response: http_response)
      raise ApiError.new(response) if @raise_on_error && !response.success?
      response
    rescue ApiError
      raise
    rescue => e
      @logger.error { "Request failed: #{e.message}" }
      response = Response.new(error: e.message)
      raise ApiError.new(response) if @raise_on_error
      response
    end
  end
end
