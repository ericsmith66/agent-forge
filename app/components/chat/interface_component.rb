class Chat::InterfaceComponent < ViewComponent::Base
  delegate :turbo_frame_tag, to: :helpers
  def initialize(task:)
    @task = task
    @messages = task.messages.ordered
  end
end
