require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "valid message" do
    assert messages(:user_message).valid?
  end

  test "requires role" do
    msg = Message.new(task: tasks(:pending_task), content: "hi")
    msg.role = nil
    assert_not msg.valid?
  end

  test "requires content" do
    msg = Message.new(task: tasks(:pending_task), role: "user", content: "")
    assert_not msg.valid?
  end
end
