# frozen_string_literal: true

require_relative '../../test_helper'
require 'webmock/minitest'
require 'json'

# WebMock-based tests for AiderDesk::Client HTTP methods.
# Covers all public API methods with stubbed HTTP responses.
class AiderDesk::ClientWebMockTest < Minitest::Test
  BASE_URL = 'http://localhost:24337'
  PROJECT_DIR = '/tmp/test-project'

  def setup
    @logger = Logger.new(StringIO.new, level: Logger::DEBUG)
    @client = AiderDesk::Client.new(
      base_url: BASE_URL,
      project_dir: PROJECT_DIR,
      logger: @logger
    )
  end

  # ─── Settings ──────────────────────────────────────────────────────────

  def test_get_settings
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 200, body: '{"mainModel":"claude"}', headers: { 'Content-Type' => 'application/json' })

    response = @client.get_settings
    assert response.success?
    assert_equal 'claude', response.data['mainModel']
  end

  def test_update_settings
    stub_request(:post, "#{BASE_URL}/api/settings")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.update_settings({ 'mainModel' => 'gpt-4' })
    assert response.success?
  end

  # ─── Projects ──────────────────────────────────────────────────────────

  def test_get_projects
    stub_request(:get, "#{BASE_URL}/api/projects")
      .to_return(status: 200, body: '[{"dir":"/tmp/p1"}]')

    response = @client.get_projects
    assert response.success?
  end

  def test_add_open_project
    stub_request(:post, "#{BASE_URL}/api/project/add-open")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.add_open_project
    assert response.success?
  end

  def test_remove_open_project
    stub_request(:post, "#{BASE_URL}/api/project/remove-open")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.remove_open_project
    assert response.success?
  end

  def test_get_project_settings
    stub_request(:get, "#{BASE_URL}/api/project/settings?projectDir=#{PROJECT_DIR}")
      .to_return(status: 200, body: '{"editFormat":"diff"}')

    response = @client.get_project_settings
    assert response.success?
  end

  def test_start_project
    stub_request(:post, "#{BASE_URL}/api/project/start")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.start_project
    assert response.success?
  end

  def test_stop_project
    stub_request(:post, "#{BASE_URL}/api/project/stop")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.stop_project
    assert response.success?
  end

  def test_restart_project
    stub_request(:post, "#{BASE_URL}/api/project/restart")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.restart_project
    assert response.success?
  end

  # ─── Tasks ─────────────────────────────────────────────────────────────

  def test_create_task
    stub_request(:post, "#{BASE_URL}/api/project/tasks/new")
      .to_return(status: 200, body: '{"id":"t1","name":"test"}')

    response = @client.create_task(name: 'test')
    assert response.success?
    assert_equal 't1', response.data['id']
  end

  def test_create_task_and_get_id
    stub_request(:post, "#{BASE_URL}/api/project/tasks/new")
      .to_return(status: 200, body: '{"id":"t2","name":"test"}')

    task_id = @client.create_task_and_get_id(name: 'test')
    assert_equal 't2', task_id
  end

  def test_create_task_and_get_id_returns_nil_on_failure
    stub_request(:post, "#{BASE_URL}/api/project/tasks/new")
      .to_return(status: 500, body: '{"error":"fail"}')

    task_id = @client.create_task_and_get_id(name: 'test')
    assert_nil task_id
  end

  def test_list_tasks
    stub_request(:get, "#{BASE_URL}/api/project/tasks?projectDir=#{PROJECT_DIR}")
      .to_return(status: 200, body: '[{"id":"t1"}]')

    response = @client.list_tasks
    assert response.success?
  end

  def test_load_task
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t1","messages":[]}')

    response = @client.load_task(task_id: 't1')
    assert response.success?
  end

  def test_delete_task
    stub_request(:post, "#{BASE_URL}/api/project/tasks/delete")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.delete_task(task_id: 't1')
    assert response.success?
  end

  def test_task_status
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t1","status":"active","messages":[]}')

    data = @client.task_status(task_id: 't1')
    assert_equal 't1', data['id']
  end

  def test_task_status_returns_nil_on_failure
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 500, body: '{"error":"fail"}')

    data = @client.task_status(task_id: 't1')
    assert_nil data
  end

  def test_task_messages
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t1","messages":[{"type":"text","content":"hi"}]}')

    messages = @client.task_messages(task_id: 't1')
    assert_equal 1, messages.length
    assert_equal 'text', messages.first['type']
  end

  def test_task_messages_returns_empty_on_failure
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 500, body: '{"error":"fail"}')

    messages = @client.task_messages(task_id: 't1')
    assert_equal [], messages
  end

  # ─── Prompts ───────────────────────────────────────────────────────────

  def test_run_prompt
    stub_request(:post, "#{BASE_URL}/api/run-prompt")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.run_prompt(task_id: 't1', prompt: 'hello', mode: 'code')
    assert response.success?
  end

  def test_run_prompt_and_wait_completes
    stub_request(:post, "#{BASE_URL}/api/run-prompt")
      .to_return(status: 200, body: '{"ok":true}')
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t1","messages":[{"type":"response-completed","content":"done"}]}')

    collected = []
    result = @client.run_prompt_and_wait(
      task_id: 't1', prompt: 'hello', mode: 'code', timeout: 10, poll_interval: 0.1
    ) { |msg| collected << msg }

    assert result.is_a?(AiderDesk::Response)
    assert result.success?
    assert_equal 1, collected.length
  end

  def test_run_prompt_and_wait_returns_on_run_failure
    stub_request(:post, "#{BASE_URL}/api/run-prompt")
      .to_return(status: 500, body: '{"error":"fail"}')

    result = @client.run_prompt_and_wait(
      task_id: 't1', prompt: 'hello', mode: 'code', timeout: 5
    )

    refute result.success?
  end

  def test_run_and_wait_full_flow
    stub_request(:post, "#{BASE_URL}/api/project/tasks/new")
      .to_return(status: 200, body: '{"id":"t3","name":"auto"}')
    stub_request(:post, "#{BASE_URL}/api/run-prompt")
      .to_return(status: 200, body: '{"ok":true}')
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t3","messages":[{"type":"response-completed","content":"done"}]}')

    result = @client.run_and_wait(prompt: 'hello', timeout: 10, poll_interval: 0.1)
    assert_equal 't3', result[:task_id]
    assert_equal 1, result[:messages].length
  end

  def test_run_and_wait_task_creation_failure
    stub_request(:post, "#{BASE_URL}/api/project/tasks/new")
      .to_return(status: 500, body: '{"error":"fail"}')

    result = @client.run_and_wait(prompt: 'hello')
    assert_nil result[:task_id]
    assert_equal [], result[:messages]
  end

  # ─── Context Files ─────────────────────────────────────────────────────

  def test_add_context_file
    stub_request(:post, "#{BASE_URL}/api/add-context-file")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.add_context_file(task_id: 't1', path: 'app/models/user.rb')
    assert response.success?
  end

  def test_drop_context_file
    stub_request(:post, "#{BASE_URL}/api/drop-context-file")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.drop_context_file(task_id: 't1', path: 'app/models/user.rb')
    assert response.success?
  end

  def test_get_context_files
    stub_request(:post, "#{BASE_URL}/api/get-context-files")
      .to_return(status: 200, body: '[{"path":"app/models/user.rb"}]')

    response = @client.get_context_files(task_id: 't1')
    assert response.success?
  end

  # ─── Model Settings ────────────────────────────────────────────────────

  def test_set_main_model
    stub_request(:post, "#{BASE_URL}/api/project/settings/main-model")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.set_main_model(task_id: 't1', main_model: 'gpt-4')
    assert response.success?
  end

  # ─── Conversation ──────────────────────────────────────────────────────

  def test_interrupt
    stub_request(:post, "#{BASE_URL}/api/project/interrupt")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.interrupt(task_id: 't1')
    assert response.success?
  end

  def test_clear_context
    stub_request(:post, "#{BASE_URL}/api/project/clear-context")
      .to_return(status: 200, body: '{"ok":true}')

    response = @client.clear_context(task_id: 't1')
    assert response.success?
  end

  # ─── Error handling ────────────────────────────────────────────────────

  def test_401_without_raise
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 401, body: 'Unauthorized')

    response = @client.get_settings
    refute response.success?
    assert_equal 401, response.status
  end

  def test_401_with_raise
    client = AiderDesk::Client.new(
      base_url: BASE_URL, raise_on_error: true, logger: @logger
    )
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 401, body: 'Unauthorized')

    assert_raises(AiderDesk::AuthError) { client.get_settings }
  end

  def test_500_with_raise
    client = AiderDesk::Client.new(
      base_url: BASE_URL, raise_on_error: true, logger: @logger
    )
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 500, body: '{"error":"internal"}')

    assert_raises(AiderDesk::ApiError) { client.get_settings }
  end

  # ─── Health ────────────────────────────────────────────────────────────

  def test_health_returns_ok_hash
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 200, body: '{"mainModel":"claude"}')

    result = @client.health
    assert result[:ok]
    assert_equal 200, result[:status]
  end

  def test_health_returns_error_hash_on_failure
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 500, body: 'error')

    result = @client.health
    refute result[:ok]
  end

  def test_health_check_boolean
    stub_request(:get, "#{BASE_URL}/api/settings")
      .to_return(status: 200, body: '{"ok":true}')

    assert @client.health_check
  end

  # ─── Response edge cases ─────────────────────────────────────────────

  def test_response_to_s_error
    response = AiderDesk::Response.new(error: "something broke")
    assert_match(/something broke/, response.to_s)
  end

  def test_response_empty_body_returns_nil_data
    http_resp = Object.new
    http_resp.define_singleton_method(:code) { '200' }
    http_resp.define_singleton_method(:body) { '' }
    response = AiderDesk::Response.new(http_response: http_resp)
    assert_nil response.data
  end

  # ─── Credential loading ────────────────────────────────────────────────

  def test_client_without_rails_credentials
    # Ensure no Rails defined — default path
    client = AiderDesk::Client.new(base_url: BASE_URL, logger: @logger)
    assert_equal BASE_URL, client.base_url
  end

  # ─── resolve_project_dir ───────────────────────────────────────────────

  def test_raises_without_project_dir
    client = AiderDesk::Client.new(base_url: BASE_URL, logger: @logger)
    assert_raises(ArgumentError) { client.list_tasks }
  end

  # ─── run_prompt_and_wait timeout ───────────────────────────────────────

  def test_run_prompt_and_wait_timeout
    stub_request(:post, "#{BASE_URL}/api/run-prompt")
      .to_return(status: 200, body: '{"ok":true}')
    stub_request(:post, "#{BASE_URL}/api/project/tasks/load")
      .to_return(status: 200, body: '{"id":"t1","messages":[{"type":"text","content":"thinking..."}]}')

    result = @client.run_prompt_and_wait(
      task_id: 't1', prompt: 'hello', mode: 'code', timeout: 0.1, poll_interval: 0.05
    )

    assert result.is_a?(Hash)
    assert_equal :timeout, result[:status]
  end

  # ─── apply_edits with preview_only: false ──────────────────────────────

  def test_apply_edits_allowed_when_preview_off
    client = AiderDesk::Client.new(
      base_url: BASE_URL, project_dir: PROJECT_DIR,
      preview_only: false, logger: @logger
    )
    stub_request(:post, "#{BASE_URL}/api/project/apply-edits")
      .to_return(status: 200, body: '{"ok":true}')

    response = client.apply_edits(task_id: 't1', edits: [{ 'file' => 'a.rb' }])
    assert response.success?
  end
end
