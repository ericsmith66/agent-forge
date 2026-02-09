# frozen_string_literal: true

module ToolAdapter
  # Base class for ToolAdapter adapters.
  # Subclasses must implement #run_prompt(task_id, prompt, mode, project_dir).
  class BaseAdapter
    attr_reader :logger

    def initialize(logger: nil)
      @logger = logger || default_logger
    end

    # @param task_id [String, nil] existing task ID, or nil to create a new task
    # @param prompt [String] the prompt to send
    # @param mode [String] AiderDesk mode (e.g. "code", "agent")
    # @param project_dir [String] path to the project directory
    # @return [Hash] structured result with :status, :diffs, :messages keys
    def run_prompt(task_id, prompt, mode, project_dir)
      raise NotImplementedError, "#{self.class}#run_prompt must be implemented"
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger
      else
        require 'logger'
        Logger.new($stdout, level: Logger::WARN)
      end
    end
  end
end
