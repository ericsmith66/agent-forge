# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/knowledge_base/"
  add_filter "/projects/"

  add_group "AiderDesk Client", "lib/aider_desk"
  add_group "ToolAdapter", "lib/tool_adapter"
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"

  minimum_coverage 10
  minimum_coverage_by_file 0
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require "minitest/autorun"
require "minitest/pride"
require "view_component/test_helpers"
require "view_component/system_test_helpers"

module ActiveSupport
  class TestCase
    include Capybara::Minitest::Assertions
    include ViewComponent::TestHelpers
    include ViewComponent::SystemTestHelpers
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
