# frozen_string_literal: true

# Run all tests in a single process for SimpleCov coverage.
# Usage: ruby -Ilib:test test/run_all_tests.rb

require_relative 'test_helper'

# Load WebMock early so all tests can use it
require 'webmock/minitest'
# Allow real connections for CLI subprocess tests
WebMock.allow_net_connect!

# Load all test files
test_root = File.expand_path(__dir__)
test_files = Dir.glob("#{test_root}/**/*_test.rb").sort

test_files.each do |f|
  next if f == __FILE__
  require f
end
