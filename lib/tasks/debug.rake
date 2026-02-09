namespace :debug do
  desc "Tail the browser debug log"
  task tail: :environment do
    log_file = Rails.root.join("log/browser_debug.log")
    FileUtils.touch(log_file) unless File.exist?(log_file)
    system("tail -f #{log_file}")
  end

  desc "Clear the browser debug log"
  task clear: :environment do
    log_file = Rails.root.join("log/browser_debug.log")
    File.truncate(log_file, 0) if File.exist?(log_file)
    puts "Browser debug log cleared."
  end
end
