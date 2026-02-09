# frozen_string_literal: true

require_relative '../../test_helper'

# Integration tests against live AiderDesk instance.
# These tests require AiderDesk running on localhost:24337.
# Skip with: SKIP_INTEGRATION=1 ruby -Itest test/integration/aider_desk/client_integration_test.rb
class AiderDesk::ClientIntegrationTest < Minitest::Test
  def setup
    skip "Set SKIP_INTEGRATION=0 to run integration tests" unless ENV['SKIP_INTEGRATION'] == '0'

    @client = AiderDesk::Client.new(
      logger: Logger.new($stdout, level: Logger::INFO)
    )
  end

  def test_health_check
    result = @client.health
    assert result[:ok], "Expected health check to pass: #{result[:error]}"
    assert_equal 200, result[:status]
  end

  def test_get_settings
    response = @client.get_settings
    assert response.success?, "Expected settings to return 200: #{response}"
    assert response.data.is_a?(Hash), "Expected settings data to be a Hash"
  end

  def test_create_task
    skip "Requires AIDER_PROJECT_DIR" unless ENV['AIDER_PROJECT_DIR']

    response = @client.create_task(name: "integration-test-#{Time.now.to_i}")
    assert response.success?, "Expected task creation to succeed: #{response}"
    assert response.data&.dig("id"), "Expected task to have an ID"

    # Cleanup
    task_id = response.data["id"]
    @client.delete_task(task_id: task_id) if task_id
  end

  def test_prompt_execution
    skip "Requires AIDER_PROJECT_DIR" unless ENV['AIDER_PROJECT_DIR']

    result = @client.run_and_wait(
      prompt: "Say hello",
      name: "integration-test-prompt",
      timeout: 30,
      poll_interval: 2
    ) do |msg|
      puts "  [#{msg['type'] || 'unknown'}] #{msg.fetch('content', '')[0..80]}"
    end

    assert result[:task_id], "Expected a task ID"

    # Cleanup
    @client.delete_task(task_id: result[:task_id]) if result[:task_id]
  end
end
