# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/knowledge_base/'
  add_filter '/projects/'

  add_group 'AiderDesk Client', 'lib/aider_desk'
  add_group 'ToolAdapter', 'lib/tool_adapter'

  minimum_coverage 90
  minimum_coverage_by_file 80
end

require 'minitest/autorun'
require 'minitest/pride'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'aider_desk/client'
