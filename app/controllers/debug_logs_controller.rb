class DebugLogsController < ApplicationController
  skip_before_action :verify_authenticity_token if Rails.env.development?

  def create
    return head :not_found unless Rails.env.development? || Rails.env.test?

    level = params[:level].to_s.upcase
    message = params[:message]
    url = params[:url]
    timestamp = params[:timestamp]
    user_agent = params[:userAgent]
    viewport = params[:viewport]

    log_line = "[#{timestamp}] [#{level}] #{message} (#{url}) [UA: #{user_agent}] [VP: #{viewport}]\n"
    File.open(Rails.root.join("log/browser_debug.log"), "a") do |f|
      f.write(log_line)
    end

    head :no_content
  end
end
