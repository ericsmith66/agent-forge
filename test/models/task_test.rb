require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    assert tasks(:pending_task).valid?
  end

  test "requires status" do
    task = Task.new(project: projects(:agent_forge))
    task.status = nil
    assert_not task.valid?
  end

  test "has many messages" do
    task = tasks(:pending_task)
    assert_respond_to task, :messages
    assert task.messages.count > 0
  end
end
