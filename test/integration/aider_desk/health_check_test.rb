# frozen_string_literal: true

require_relative '../../test_helper'
require 'webmock/minitest'

# VCR-style integration tests using WebMock stubs matching recorded cassette data.
# To re-record: run against live AiderDesk and update stubs.
class AiderDesk::HealthCheckIntegrationTest < Minitest::Test
  SETTINGS_BODY = '{"mainModel":"claude-sonnet-4-20250514","editFormat":"diff","autoCommit":false}'

  def test_health_check_returns_ok
    stub_request(:get, 'http://localhost:24337/api/settings')
      .to_return(status: 200, body: SETTINGS_BODY)

    client = AiderDesk::Client.new(logger: Logger.new(StringIO.new, level: Logger::DEBUG))
    result = client.health
    assert result[:ok], "Expected health check to pass"
    assert_equal 200, result[:status]
    assert result[:data].is_a?(Hash)
    assert result[:data].key?("mainModel")
  end

  def test_health_check_boolean
    stub_request(:get, 'http://localhost:24337/api/settings')
      .to_return(status: 200, body: SETTINGS_BODY)

    client = AiderDesk::Client.new(logger: Logger.new(StringIO.new, level: Logger::DEBUG))
    assert client.health_check
  end

  def test_get_settings
    stub_request(:get, 'http://localhost:24337/api/settings')
      .to_return(status: 200, body: SETTINGS_BODY)

    client = AiderDesk::Client.new(logger: Logger.new(StringIO.new, level: Logger::DEBUG))
    response = client.get_settings
    assert response.success?
    assert response.data.is_a?(Hash)
    assert_equal 'claude-sonnet-4-20250514', response.data['mainModel']
  end
end
