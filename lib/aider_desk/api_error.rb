# frozen_string_literal: true

module AiderDesk
  # Base error for all AiderDesk API failures
  class ApiError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      super("AiderDesk API error #{response.status}: #{response.error || response.body}")
    end
  end

  # Raised when AiderDesk is unreachable (connection refused, DNS failure, etc.)
  class ConnectionError < ApiError
    def initialize(url, original_error = nil)
      msg = "AiderDesk not running on #{url}. Start the desktop app."
      msg += " (#{original_error.message})" if original_error
      # Build a minimal response-like object for compatibility
      response = Response.new(error: msg)
      super(response)
    end
  end

  # Raised on 401 Unauthorized
  class AuthError < ApiError
    def initialize(response = nil)
      if response
        super(response)
      else
        resp = Response.new(error: "Invalid credentials. Check Rails credentials.")
        super(resp)
      end
    end
  end
end
