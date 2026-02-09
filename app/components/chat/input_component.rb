class Chat::InputComponent < ViewComponent::Base
  def initialize(task:)
    @task = task
  end
end
