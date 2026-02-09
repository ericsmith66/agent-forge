# frozen_string_literal: true

require_relative '../../test_helper'

class AiderDesk::ApiErrorTest < Minitest::Test
  def test_api_error_includes_status_and_body
    http_resp = mock_http_response(code: "500", body: "Internal Server Error")
    response = AiderDesk::Response.new(http_response: http_resp)
    error = AiderDesk::ApiError.new(response)

    assert_equal 500, error.response.status
    assert_match(/500/, error.message)
    assert_match(/Internal Server Error/, error.message)
  end

  def test_api_error_with_error_string
    response = AiderDesk::Response.new(error: "something broke")
    error = AiderDesk::ApiError.new(response)

    assert_equal 0, error.response.status
    assert_match(/something broke/, error.message)
  end

  def test_connection_error_message
    error = AiderDesk::ConnectionError.new("http://localhost:24337")

    assert_match(/AiderDesk not running/, error.message)
    assert_match(/localhost:24337/, error.message)
  end

  def test_connection_error_with_original
    original = Errno::ECONNREFUSED.new("Connection refused")
    error = AiderDesk::ConnectionError.new("http://localhost:24337", original)

    assert_match(/AiderDesk not running/, error.message)
    assert_match(/Connection refused/, error.message)
  end

  def test_auth_error_default
    error = AiderDesk::AuthError.new

    assert_match(/Invalid credentials/, error.message)
  end

  def test_auth_error_with_response
    http_resp = mock_http_response(code: "401", body: "Unauthorized")
    response = AiderDesk::Response.new(http_response: http_resp)
    error = AiderDesk::AuthError.new(response)

    assert_equal 401, error.response.status
  end

  def test_all_errors_inherit_from_standard_error
    assert AiderDesk::ApiError < StandardError
    assert AiderDesk::ConnectionError < AiderDesk::ApiError
    assert AiderDesk::AuthError < AiderDesk::ApiError
  end

  private

  def mock_http_response(code:, body: "")
    resp = Object.new
    resp.define_singleton_method(:code) { code }
    resp.define_singleton_method(:body) { body }
    resp
  end
end
