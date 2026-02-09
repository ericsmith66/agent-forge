class DebugLogsController < ApplicationController
  skip_before_action :verify_authenticity_token if Rails.env.development?

  def create
    return head :not_found unless Rails.env.development?

    level = params[:level].to_s.upcase
    message = params[:message]
    url = params[:url]
    timestamp = params[:timestamp]

    log_line = "[#{timestamp}] [#{level}] #{message} (#{url})\n"
    
    File.open(Rails.root.join("log/browser_debug.log"), "a") do |f|
      f.write(log_line)
    end

    head :no_content
  end
end
