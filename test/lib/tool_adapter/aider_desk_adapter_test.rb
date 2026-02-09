# frozen_string_literal: true

require 'test_helper'
require 'tool_adapter/aider_desk_adapter'

# Simple stub client for testing the adapter without Minitest::Mock
class StubAiderDeskClient
  attr_reader :preview_only, :health_result, :create_task_result, :run_prompt_result
  attr_accessor :captured_prompt

  def initialize(preview_only: true, health_result: true, create_task_result: nil, run_prompt_result: nil, messages: [])
    @preview_only = preview_only
    @health_result = health_result
    @create_task_result = create_task_result
    @run_prompt_result = run_prompt_result
    @messages = messages
    @captured_prompt = nil
  end

  def health_check
    @health_result
  end

  def create_task_and_get_id(project_dir:)
    @create_task_result
  end

  def load_task(task_id:, project_dir:)
    # stub — returns nil, adapter doesn't check the result
    nil
  end

  # Matches the blocking /api/run-prompt call
  def run_prompt(task_id:, prompt:, mode:, project_dir:)
    @captured_prompt = prompt
    @run_prompt_result
  end

  def task_messages(task_id:, project_dir:)
    @messages
  end
end

class ToolAdapter::AiderDeskAdapterTest < Minitest::Test
  def setup
    @projects_root = File.expand_path('../../../projects', __dir__)
    @valid_project_dir = File.join(@projects_root, 'test-project')
    @logger = Logger.new(StringIO.new, level: Logger::DEBUG)
  end

  def build_adapter(client:, **opts)
    ToolAdapter::AiderDeskAdapter.new(client: client, logger: @logger, **opts)
  end

  def success_response(body = '{"messages":[]}')
    resp = Object.new
    resp.define_singleton_method(:code) { '200' }
    resp.define_singleton_method(:body) { body }
    AiderDesk::Response.new(http_response: resp)
  end

  # ─── Instantiation ──────────────────────────────────────────────────

  def test_instantiates_with_defaults
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client)
    assert_equal client, adapter.client
    assert_equal 120, adapter.polling_timeout
  end

  def test_custom_polling_timeout
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client, polling_timeout: 60)
    assert_equal 60, adapter.polling_timeout
  end

  def test_rejects_non_preview_only_client
    client = StubAiderDeskClient.new(preview_only: false)
    assert_raises(ArgumentError) do
      build_adapter(client: client)
    end
  end

  # ─── Health check ───────────────────────────────────────────────────

  def test_health_check_delegates_to_client
    client = StubAiderDeskClient.new(health_result: true)
    adapter = build_adapter(client: client)
    assert adapter.health_check
  end

  # ─── project_dir validation ─────────────────────────────────────────

  def test_rejects_nil_project_dir
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', nil)
    assert_equal :error, result[:status]
  end

  def test_rejects_empty_project_dir
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', '')
    assert_equal :error, result[:status]
  end

  def test_rejects_path_outside_projects
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', '/tmp/evil')
    assert_equal :error, result[:status]
    assert_match(/projects/, result[:error])
  end

  def test_rejects_traversal_attack
    client = StubAiderDeskClient.new
    adapter = build_adapter(client: client)
    traversal = File.join(@projects_root, '..', 'etc', 'passwd')
    result = adapter.run_prompt(nil, 'hello', 'code', traversal)
    assert_equal :error, result[:status]
  end

  def test_accepts_valid_project_dir
    client = StubAiderDeskClient.new(
      create_task_result: 'task-1',
      run_prompt_result: success_response
    )
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'Create hello.rb', 'code', @valid_project_dir)
    assert_equal :ok, result[:status]
  end

  # ─── run_prompt with healthy client ─────────────────────────────────

  def test_run_prompt_creates_task_when_nil
    client = StubAiderDeskClient.new(
      create_task_result: 'task-42',
      run_prompt_result: success_response
    )
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'Create hello.rb', 'code', @valid_project_dir)
    assert_equal :ok, result[:status]
    assert_equal 'task-42', result[:task_id]
  end

  def test_run_prompt_uses_existing_task_id
    client = StubAiderDeskClient.new(run_prompt_result: success_response)
    adapter = build_adapter(client: client)
    result = adapter.run_prompt('existing-task', 'Create hello.rb', 'code', @valid_project_dir)
    assert_equal :ok, result[:status]
    assert_equal 'existing-task', result[:task_id]
  end

  # ─── Error scenarios ────────────────────────────────────────────────

  def test_returns_error_when_aiderdesk_unreachable
    client = StubAiderDeskClient.new(health_result: false)
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', @valid_project_dir)
    assert_equal :error, result[:status]
    assert_match(/not running/, result[:error])
  end

  def test_returns_error_when_task_creation_fails
    client = StubAiderDeskClient.new(create_task_result: nil)
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', @valid_project_dir)
    assert_equal :error, result[:status]
    assert_match(/Failed to create task/, result[:error])
  end

  def test_returns_timeout_status
    timeout_result = { response: nil, status: :timeout }
    client = StubAiderDeskClient.new(
      create_task_result: 'task-t',
      run_prompt_result: timeout_result
    )
    adapter = build_adapter(client: client, polling_timeout: 1)
    result = adapter.run_prompt(nil, 'hello', 'code', @valid_project_dir)
    assert_equal :timeout, result[:status]
    assert_equal 'task-t', result[:task_id]
  end

  # ─── Shared context injection ───────────────────────────────────────

  def test_prepends_shared_context_to_prompt
    client = StubAiderDeskClient.new(
      create_task_result: 'task-ctx',
      run_prompt_result: success_response
    )
    adapter = build_adapter(client: client, shared_context: 'You are a Ruby expert.')
    adapter.run_prompt(nil, 'Create hello.rb', 'code', @valid_project_dir)
    assert_includes client.captured_prompt, 'You are a Ruby expert.'
    assert_includes client.captured_prompt, 'Create hello.rb'
  end

  def test_no_shared_context_passes_prompt_as_is
    client = StubAiderDeskClient.new(
      create_task_result: 'task-no-ctx',
      run_prompt_result: success_response
    )
    adapter = build_adapter(client: client)
    adapter.run_prompt(nil, 'Create hello.rb', 'code', @valid_project_dir)
    assert_equal 'Create hello.rb', client.captured_prompt
  end

  # ─── Tool schema ────────────────────────────────────────────────────

  def test_tool_schema_has_required_fields
    schema = ToolAdapter::AiderDeskAdapter.tool_schema
    assert_equal 'aider_desk', schema[:name]
    assert schema[:parameters].key?(:prompt)
    assert schema[:parameters].key?(:project_dir)
  end

  # ─── Diff extraction ────────────────────────────────────────────────

  def test_extracts_diffs_from_messages
    messages = [
      { 'type' => 'text', 'content' => 'thinking...' },
      { 'type' => 'diff', 'content' => '+ hello.rb' },
      { 'type' => 'edit', 'content' => 'modified file' }
    ]
    client = StubAiderDeskClient.new(
      create_task_result: 'task-diff',
      run_prompt_result: success_response,
      messages: messages
    )
    adapter = build_adapter(client: client)
    result = adapter.run_prompt(nil, 'hello', 'code', @valid_project_dir)
    assert_equal 2, result[:diffs].length
  end
end
