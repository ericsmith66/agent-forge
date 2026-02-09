# frozen_string_literal: true

require_relative '../../test_helper'
require 'json'

class AiderDesk::ClientTest < Minitest::Test
  def setup
    @logger = Logger.new(StringIO.new, level: Logger::DEBUG)
  end

  # ─── Initialization ────────────────────────────────────────────────────

  def test_default_base_url
    client = AiderDesk::Client.new(logger: @logger)
    assert_equal "http://localhost:24337", client.base_url
  end

  def test_custom_base_url
    client = AiderDesk::Client.new(base_url: "http://example.com:9999", logger: @logger)
    assert_equal "http://example.com:9999", client.base_url
  end

  def test_base_url_strips_trailing_slash
    client = AiderDesk::Client.new(base_url: "http://localhost:24337/", logger: @logger)
    assert_equal "http://localhost:24337", client.base_url
  end

  def test_preview_only_defaults_to_true
    client = AiderDesk::Client.new(logger: @logger)
    assert_equal true, client.preview_only
  end

  def test_preview_only_can_be_disabled
    client = AiderDesk::Client.new(preview_only: false, logger: @logger)
    assert_equal false, client.preview_only
  end

  def test_project_dir_from_constructor
    client = AiderDesk::Client.new(project_dir: "/tmp/test", logger: @logger)
    assert_equal "/tmp/test", client.project_dir
  end

  def test_force_apply_constant_is_false
    assert_equal false, AiderDesk::Client::FORCE_APPLY
  end

  # ─── Response ──────────────────────────────────────────────────────────

  def test_response_success
    http_resp = mock_http_response(code: "200", body: '{"ok":true}')
    response = AiderDesk::Response.new(http_response: http_resp)

    assert response.success?
    assert_equal 200, response.status
    assert_equal({ "ok" => true }, response.data)
  end

  def test_response_failure
    http_resp = mock_http_response(code: "500", body: "error")
    response = AiderDesk::Response.new(http_response: http_resp)

    refute response.success?
    assert_equal 500, response.status
  end

  def test_response_with_error
    response = AiderDesk::Response.new(error: "connection failed")

    refute response.success?
    assert_equal 0, response.status
    assert_equal "connection failed", response.error
  end

  def test_response_invalid_json_returns_nil_data
    http_resp = mock_http_response(code: "200", body: "not json")
    response = AiderDesk::Response.new(http_response: http_resp)

    assert response.success?
    assert_nil response.data
  end

  def test_response_to_s_success
    http_resp = mock_http_response(code: "200", body: '{}')
    response = AiderDesk::Response.new(http_response: http_resp)

    assert_equal "Response(200)", response.to_s
  end

  # ─── apply_edits guarded by preview_only ───────────────────────────────

  def test_apply_edits_blocked_in_preview_mode
    client = AiderDesk::Client.new(
      project_dir: "/tmp/test",
      preview_only: true,
      logger: @logger
    )

    response = client.apply_edits(task_id: "t1", edits: [])
    refute response.success?
    assert_match(/preview_only/, response.error)
  end

  # ─── Method signatures exist ───────────────────────────────────────────

  def test_client_responds_to_key_methods
    client = AiderDesk::Client.new(logger: @logger)

    %i[
      health health_check get_settings get_projects
      create_task create_task_and_get_id list_tasks load_task delete_task
      task_status task_messages
      run_prompt run_prompt_and_wait run_and_wait
      add_context_file drop_context_file get_context_files
      apply_edits set_main_model interrupt clear_context
      start_project stop_project restart_project
    ].each do |method|
      assert_respond_to client, method, "Client should respond to ##{method}"
    end
  end

  # ─── Thread safety: no class-level mutable state ───────────────────────

  def test_no_class_level_mutable_state
    # FORCE_APPLY is frozen (false is immutable)
    assert_equal false, AiderDesk::Client::FORCE_APPLY

    # Two clients with different configs don't interfere
    c1 = AiderDesk::Client.new(base_url: "http://host1:1111", project_dir: "/a", logger: @logger)
    c2 = AiderDesk::Client.new(base_url: "http://host2:2222", project_dir: "/b", logger: @logger)

    assert_equal "http://host1:1111", c1.base_url
    assert_equal "http://host2:2222", c2.base_url
    assert_equal "/a", c1.project_dir
    assert_equal "/b", c2.project_dir
  end

  # ─── Error handling with raise_on_error ────────────────────────────────

  def test_connection_refused_without_raise
    client = AiderDesk::Client.new(
      base_url: "http://localhost:19999",
      raise_on_error: false,
      logger: @logger
    )

    response = client.get_settings
    refute response.success?
    assert_match(/Connection failed/, response.error)
  end

  def test_connection_refused_with_raise
    client = AiderDesk::Client.new(
      base_url: "http://localhost:19999",
      raise_on_error: true,
      logger: @logger
    )

    assert_raises(AiderDesk::ConnectionError) { client.get_settings }
  end

  private

  def mock_http_response(code:, body: "")
    resp = Object.new
    resp.define_singleton_method(:code) { code }
    resp.define_singleton_method(:body) { body }
    resp
  end
end
