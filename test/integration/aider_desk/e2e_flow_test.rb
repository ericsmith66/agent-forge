# frozen_string_literal: true

require_relative '../../test_helper'
require 'webmock/minitest'
require 'tool_adapter/aider_desk_adapter'

# End-to-end flow: prompt → adapter → AiderDesk → file change proposed in test project
class AiderDesk::E2EFlowIntegrationTest < Minitest::Test
  BASE = 'http://localhost:24337'
  PROJECT_DIR = '/Users/ericsmith66/development/agent-forge/projects/aider-desk-test'
  SETTINGS_BODY = '{"mainModel":"claude-sonnet-4-20250514","editFormat":"diff","autoCommit":false}'
  TASK_BODY = '{"id":"e2e-task-001","name":"default","messages":[]}'
  COMPLETED_BODY = '{"id":"e2e-task-001","name":"default","messages":[' \
    '{"type":"text","content":"I will add a comment to test_event.rb"},' \
    '{"type":"diff","content":"--- a/app/models/test_event.rb\\n+++ b/app/models/test_event.rb"},' \
    '{"type":"response-completed","content":"Done"}]}'

  def test_full_e2e_flow_via_adapter
    stub_request(:get, "#{BASE}/api/settings").to_return(status: 200, body: SETTINGS_BODY)
    stub_request(:post, "#{BASE}/api/project/tasks/new").to_return(status: 200, body: TASK_BODY)
    stub_request(:post, "#{BASE}/api/run-prompt").to_return(status: 200, body: '{"ok":true}')
    stub_request(:post, "#{BASE}/api/project/tasks/load").to_return(status: 200, body: COMPLETED_BODY)

    client = AiderDesk::Client.new(project_dir: PROJECT_DIR, logger: Logger.new(StringIO.new, level: Logger::DEBUG))
    adapter = ToolAdapter::AiderDeskAdapter.new(
      client: client, polling_timeout: 30,
      logger: Logger.new(StringIO.new, level: Logger::DEBUG)
    )

    result = adapter.run_prompt(nil, 'Add a comment to the top of app/models/test_event.rb', 'code', PROJECT_DIR)

    assert_equal :ok, result[:status]
    assert result[:task_id]
    assert result[:diffs].length >= 1, "Expected at least one diff"
    assert result[:messages].length >= 1, "Expected at least one message"

    diff_content = result[:diffs].map { |d| d['content'] }.join("\n")
    assert_match(/test_event/, diff_content)
  end

  def test_e2e_flow_directly_via_client
    stub_request(:get, "#{BASE}/api/settings").to_return(status: 200, body: SETTINGS_BODY)
    stub_request(:post, "#{BASE}/api/project/tasks/new").to_return(status: 200, body: TASK_BODY)
    stub_request(:post, "#{BASE}/api/run-prompt").to_return(status: 200, body: '{"ok":true}')
    stub_request(:post, "#{BASE}/api/project/tasks/load").to_return(status: 200, body: COMPLETED_BODY)

    client = AiderDesk::Client.new(project_dir: PROJECT_DIR, logger: Logger.new(StringIO.new, level: Logger::DEBUG))

    assert client.health_check

    task_id = client.create_task_and_get_id(project_dir: PROJECT_DIR)
    assert task_id

    collected = []
    result = client.run_prompt_and_wait(
      task_id: task_id, prompt: 'Add a comment', mode: 'code',
      timeout: 30, poll_interval: 0.1, project_dir: PROJECT_DIR
    ) { |msg| collected << msg }

    assert result.is_a?(AiderDesk::Response)
    assert result.success?
    assert(collected.any? { |m| m['type'] == 'diff' })
    assert(collected.any? { |m| m['type'] == 'response-completed' })
  end
end
