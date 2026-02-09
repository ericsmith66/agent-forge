# frozen_string_literal: true

require 'pathname'
require_relative 'base_adapter'
require_relative '../aider_desk/client'

module ToolAdapter
  # Adapter wrapping AiderDesk::Client for use as an ai-agents tool (formerly SmartProxy).
  #
  # Safety: preview_only is always enforced — no edits are auto-applied.
  # project_dir is validated to be within the projects/ directory.
  class AiderDeskAdapter < BaseAdapter
    TOOL_NAME = 'aider_desk'
    TOOL_SCHEMA = {
      name: TOOL_NAME,
      description: 'Send a coding prompt to AiderDesk for execution. Returns diffs for preview only.',
      parameters: {
        prompt: { type: 'string', required: true, description: 'The coding prompt to execute' },
        mode: { type: 'string', required: false, description: 'AiderDesk mode (code, agent). Default: agent' },
        project_dir: { type: 'string', required: true, description: 'Path to the project directory (must be under projects/)' }
      }
    }.freeze

    attr_reader :client, :polling_timeout

    # @param client [AiderDesk::Client, nil] pre-configured client, or nil to create default
    # @param polling_timeout [Integer] max seconds to wait for prompt completion (default 120)
    # @param shared_context [String, nil] ai-agents shared context to prepend to prompts
    # @param logger [Logger, nil]
    def initialize(client: nil, polling_timeout: 120, shared_context: nil, logger: nil)
      super(logger: logger)
      @client = client || AiderDesk::Client.new(preview_only: true, logger: @logger)
      @polling_timeout = polling_timeout
      @shared_context = shared_context

      # Enforce preview_only safety
      unless @client.preview_only
        raise ArgumentError, 'AiderDeskAdapter requires preview_only: true on the client'
      end
    end

    # Run a prompt through AiderDesk with polling.
    #
    # @param task_id [String, nil] existing task ID, or nil to create a new task
    # @param prompt [String] the coding prompt
    # @param mode [String] AiderDesk mode (default "agent")
    # @param project_dir [String] project directory path (must be under projects/)
    # @return [Hash] { status:, task_id:, diffs:, messages: }
    def run_prompt(task_id, prompt, mode = 'agent', project_dir)
      abs_project_dir = validate_project_dir!(project_dir)
      full_prompt = build_prompt(prompt)

      logger.info { "AiderDeskAdapter#run_prompt: mode=#{mode} project_dir=#{abs_project_dir}" }

      # Health check first
      unless client_healthy?
        logger.error { 'AiderDesk not running' }
        return error_result('AiderDesk not running')
      end

      # Create task if needed
      if task_id.nil?
        task_id = @client.create_task_and_get_id(project_dir: abs_project_dir)
        if task_id.nil?
          logger.error { 'Failed to create task in AiderDesk' }
          return error_result('Failed to create task in AiderDesk')
        end
      end

      # Load (activate) the task — required before run-prompt will work
      @client.load_task(task_id: task_id, project_dir: abs_project_dir)

      logger.info { "AiderDeskAdapter: running prompt on task #{task_id}" }

      # NOTE: /api/run-prompt is a blocking endpoint — it returns only after
      # the LLM finishes processing. No polling needed.
      result = @client.run_prompt(
        task_id: task_id,
        prompt: full_prompt,
        mode: mode,
        project_dir: abs_project_dir
      )

      # After the blocking call completes, load the task to get messages
      messages = @client.task_messages(task_id: task_id, project_dir: abs_project_dir)

      build_result(task_id, result, messages)
    rescue => e
      logger.error { "AiderDeskAdapter error: #{e.class} — #{e.message}" }
      error_result(e.message)
    end

    # Tool schema for ai-agents gem registration
    def self.tool_schema
      TOOL_SCHEMA
    end

    # Health check passthrough
    def health_check
      @client.health_check
    end

    private

    # Validates and returns the absolute project_dir path.
    def validate_project_dir!(project_dir)
      raise ArgumentError, 'project_dir is required' if project_dir.nil? || project_dir.empty?

      resolved = resolve_projects_root
      clean_path = File.expand_path(Pathname.new(project_dir).cleanpath.to_s)

      unless clean_path.start_with?(resolved)
        raise ArgumentError, "project_dir must be under projects/ — got: #{project_dir}"
      end

      clean_path
    end

    def resolve_projects_root
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.join('projects').to_s
      else
        File.expand_path('../../projects', __dir__)
      end
    end

    def build_prompt(prompt)
      if @shared_context && !@shared_context.empty?
        "#{@shared_context}\n\n---\n\n#{prompt}"
      else
        prompt
      end
    end

    def client_healthy?
      @client.health_check
    rescue => e
      logger.error { "Health check failed: #{e.message}" }
      false
    end

    def build_result(task_id, result, collected_messages)
      if result.is_a?(Hash) && result[:status] == :timeout
        logger.warn { "AiderDeskAdapter: polling timed out for task #{task_id}" }
        {
          status: :timeout,
          task_id: task_id,
          diffs: extract_diffs(collected_messages),
          messages: collected_messages
        }
      elsif result.is_a?(AiderDesk::Response) && result.success?
        {
          status: :ok,
          task_id: task_id,
          diffs: extract_diffs(collected_messages),
          messages: collected_messages
        }
      else
        {
          status: :error,
          task_id: task_id,
          diffs: [],
          messages: collected_messages
        }
      end
    end

    def extract_diffs(messages)
      messages.select { |m| m['type'] == 'diff' || m['type'] == 'edit' }
    end

    def error_result(message)
      { status: :error, task_id: nil, diffs: [], messages: [], error: message }
    end
  end
end
