# frozen_string_literal: true

require_relative '../test_helper'

# System tests for bin/aider_cli commands.
# These test the CLI script as a subprocess, verifying output and exit codes.
class AiderCliTest < Minitest::Test
  CLI_PATH = File.expand_path('../../bin/aider_cli', __dir__)

  def test_cli_exists_and_is_executable
    assert File.exist?(CLI_PATH), "bin/aider_cli should exist"
    assert File.executable?(CLI_PATH), "bin/aider_cli should be executable"
  end

  def test_no_command_shows_usage_and_exits_nonzero
    output, status = run_cli('')
    refute status.success?
    assert_match(/No command specified/, output)
    assert_match(/Usage:/, output)
  end

  def test_unknown_command_shows_error
    output, status = run_cli('nonexistent')
    refute status.success?
    assert_match(/Unknown command/, output)
  end

  def test_help_flag_shows_usage
    output, status = run_cli('--help')
    assert status.success?
    assert_match(/Usage:/, output)
    assert_match(/health/, output)
    assert_match(/prompt:quick/, output)
  end

  def test_health_against_unreachable_server
    output, status = run_cli('health --url http://localhost:19999')
    refute status.success?
    assert_match(/ERROR.*unreachable|Connection failed/i, output)
  end

  def test_prompt_quick_without_text_exits_nonzero
    output, status = run_cli('prompt:quick --url http://localhost:19999')
    refute status.success?
    assert_match(/No prompt text provided|ERROR/i, output)
  end

  private

  def run_cli(args_string)
    cmd = "ruby #{CLI_PATH} #{args_string} 2>&1"
    output = `#{cmd}`
    [output, $?]
  end
end
