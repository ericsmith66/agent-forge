# frozen_string_literal: true

require_relative '../../test_helper'
require 'webmock/minitest'

class AiderDesk::TaskCreationIntegrationTest < Minitest::Test
  BASE = 'http://localhost:24337'
  PROJECT_DIR = '/Users/ericsmith66/development/agent-forge/projects/aider-desk-test'
  SETTINGS_BODY = '{"mainModel":"claude-sonnet-4-20250514","editFormat":"diff","autoCommit":false}'

  def test_create_task_returns_id
    stub_request(:get, "#{BASE}/api/settings").to_return(status: 200, body: SETTINGS_BODY)
    stub_request(:post, "#{BASE}/api/project/tasks/new")
      .to_return(status: 200, body: '{"id":"vcr-task-001","name":"vcr-test-task","messages":[]}')
    stub_request(:post, "#{BASE}/api/project/tasks/delete")
      .to_return(status: 200, body: '{"ok":true}')

    client = AiderDesk::Client.new(project_dir: PROJECT_DIR, logger: Logger.new(StringIO.new, level: Logger::DEBUG))

    assert client.health_check

    response = client.create_task(name: 'vcr-test-task', project_dir: PROJECT_DIR)
    assert response.success?
    assert_equal 'vcr-task-001', response.data['id']

    client.delete_task(task_id: 'vcr-task-001', project_dir: PROJECT_DIR)
  end

  def test_create_task_and_get_id
    stub_request(:get, "#{BASE}/api/settings").to_return(status: 200, body: SETTINGS_BODY)
    stub_request(:post, "#{BASE}/api/project/tasks/new")
      .to_return(status: 200, body: '{"id":"vcr-task-001","name":"vcr-test-task","messages":[]}')
    stub_request(:post, "#{BASE}/api/project/tasks/delete")
      .to_return(status: 200, body: '{"ok":true}')

    client = AiderDesk::Client.new(project_dir: PROJECT_DIR, logger: Logger.new(StringIO.new, level: Logger::DEBUG))
    client.health_check

    task_id = client.create_task_and_get_id(name: 'vcr-test-task', project_dir: PROJECT_DIR)
    assert_equal 'vcr-task-001', task_id

    client.delete_task(task_id: task_id, project_dir: PROJECT_DIR)
  end
end
